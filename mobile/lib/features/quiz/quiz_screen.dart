import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import 'quiz_result_screen.dart';
import 'quiz_session.dart';
import 'review.dart';

/// Test ishlash ekrani: kitob, aralash va maxsus testlar uchun umumiy.
/// Pop natijasi: `true` — natija yuborildi.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.session});

  final QuizSession session;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  QuizSession get s => widget.session;
  Timer? _timer;
  bool _submitting = false;
  String? _submitError;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (s.isFinished) {
      // Oldin tugatilgan, lekin yuborilmagan — darhol yuboramiz.
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    } else {
      s.enterCurrent();
      s.save();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
    if (state == AppLifecycleState.paused) s.save();
  }

  // ---------------- taymer ----------------

  void _tick() {
    if (!mounted || s.isFinished || _submitting) return;

    final total = s.totalRemaining;
    if (total != null && total <= 0) {
      _finish(auto: true, reason: 'Test vaqti tugadi');
      return;
    }

    if (s.timing.hasPerQuestion) {
      var changed = false;
      // Fonda turgan paytda vaqti o'tib ketgan savollarni ham yopamiz.
      for (final q in s.questions) {
        final d = s.questionDeadlines[q.id];
        if (d != null && !s.isAnswered(q) && !s.isLocked(q) && DateTime.now().millisecondsSinceEpoch >= d) {
          s.locked.add(q.id);
          changed = true;
        }
      }
      final cur = s.questions[s.current];
      if (changed) {
        s.save();
        if (s.timing.forceNext && s.isLocked(cur)) {
          _advanceForced();
          return;
        }
      }
    }
    setState(() {});
  }

  /// forceNext: vaqti tugagan savoldan keyingisiga o'tish (oxirgisida — tugatish).
  void _advanceForced() {
    final next = _nextOpenIndex(from: s.current + 1);
    if (next == null) {
      _finish(auto: true, reason: 'Savollar tugadi');
      return;
    }
    _goTo(next);
  }

  int? _nextOpenIndex({required int from}) {
    for (var i = from; i < s.total; i++) {
      final q = s.questions[i];
      if (!s.isLocked(q)) return i;
    }
    return null;
  }

  // ---------------- amallar ----------------

  void _goTo(int index) {
    if (index < 0 || index >= s.total) return;
    setState(() {
      s.current = index;
      s.enterCurrent();
    });
    s.save();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _select(QuizQuestion q, QuizOption o) {
    if (!s.canAnswer(q)) return;
    setState(() => s.answers[q.id] = o.original);
    s.save();
  }

  void _next() {
    if (s.current < s.total - 1) {
      if (s.timing.forceNext) {
        final n = _nextOpenIndex(from: s.current + 1);
        if (n == null) {
          _askFinish();
        } else {
          _goTo(n);
        }
      } else {
        _goTo(s.current + 1);
      }
    } else {
      _askFinish();
    }
  }

  Future<void> _askFinish() async {
    final left = s.total - s.answeredCount;
    final ok = await confirmDialog(
      context,
      title: 'Testni yakunlaysizmi?',
      message: left > 0
          ? "$left ta savolga javob berilmagan. Javobsiz savollar noto'g'ri hisoblanadi."
          : "Barcha savollarga javob berdingiz. Natijani yuboramizmi?",
      confirm: 'Yakunlash',
    );
    if (ok) _finish(auto: false);
  }

  Future<void> _finish({required bool auto, String? reason}) async {
    if (s.isFinished) return;
    _timer?.cancel();
    s.finishedAt = DateTime.now();
    await s.save();
    if (auto && reason != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$reason — natija yuborilmoqda')));
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final r = await s.submit();
      final hasKey = r.key.values.any((v) => v.isNotEmpty);
      final review = hasKey ? ReviewData.fromSession(s, key: r.key) : null;
      await s.discard();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            title: s.title,
            solved: r.solved,
            total: r.total,
            passPercent: s.passPercent,
            showPass: s.kind == QuizKind.book,
            review: review,
          ),
        ),
        result: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Maxsus test muddati tugagan bo'lsa — qayta yuborishdan foyda yo'q.
      final fatal = s.kind == QuizKind.special && const [403, 404, 409].contains(e.statusCode);
      if (fatal) await s.discard();
      setState(() {
        _submitting = false;
        _submitError = fatal ? '${e.message}\nNatija qabul qilinmadi.' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Natijani yuborib bo\'lmadi';
      });
    }
  }

  Future<bool> _confirmExit() async {
    if (s.isFinished) return true;
    final timed = s.timing.isTimed;
    return confirmDialog(
      context,
      title: 'Testdan chiqasizmi?',
      message: timed
          ? "Javoblaringiz saqlanadi, lekin vaqt to'xtamaydi. Keyinroq shu yerdan davom ettirasiz."
          : "Javoblaringiz saqlanadi. Keyinroq shu yerdan davom ettirasiz.",
      confirm: 'Chiqish',
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _submitting) return;
        if (await _confirmExit() && context.mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
          ),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [_timerChip(), const SizedBox(width: 12)],
        ),
        body: s.isFinished ? _submitView() : _quizView(),
      ),
    );
  }

  Widget _submitView() {
    if (_submitting || _submitError == null) {
      return const LoadingView(text: 'Natija yuborilmoqda...');
    }
    final canRetry = !_submitError!.contains('qabul qilinmadi');
    return ErrorView(
      message: _submitError!,
      onRetry: canRetry ? _submit : () => Navigator.of(context).pop(false),
    );
  }

  Widget _timerChip() {
    if (s.isFinished) return const SizedBox.shrink();
    int? secs;
    if (s.timing.hasTotal) {
      secs = s.totalRemaining;
    } else if (s.timing.hasPerQuestion) {
      secs = s.questionRemaining(s.questions[s.current]);
    }
    if (secs == null) return const SizedBox.shrink();
    final danger = secs <= (s.timing.hasTotal ? 60 : 5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: danger ? AppColors.redSoft : AppColors.blueSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.timer_1, size: 16, color: danger ? AppColors.red : AppColors.blue),
          const SizedBox(width: 4),
          Text(
            formatDuration(secs),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: danger ? AppColors.red : AppColors.blue,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizView() {
    final q = s.questions[s.current];
    final answered = s.isAnswered(q);
    final locked = s.isLocked(q);
    final isLast = s.current == s.total - 1;
    final forced = s.timing.forceNext;

    return Column(
      children: [
        _progressHeader(),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                'Savol ${s.current + 1} / ${s.total}',
                style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(q.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 18),
              for (var i = 0; i < q.options.length; i++) _optionTile(q, i),
              if (locked && !answered)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Pill(
                    text: "Vaqt tugadi — javob berilmadi",
                    color: AppColors.red,
                    background: AppColors.redSoft,
                    icon: Iconsax.timer_pause,
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (!forced && s.current > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goTo(s.current - 1),
                      child: const Text('Orqaga'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Yakunlash' : 'Keyingisi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressHeader() {
    final forced = s.timing.forceNext;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: s.total == 0 ? 0 : s.answeredCount / s.total,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 3,
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              scrollDirection: Axis.horizontal,
              itemCount: s.total,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final q = s.questions[i];
                final cur = i == s.current;
                Color bg = AppColors.background, fg = AppColors.textMuted;
                if (s.isAnswered(q)) {
                  if (s.instantFeedback) {
                    final ok = s.answers[q.id] == q.correct;
                    bg = ok ? AppColors.primarySoft : AppColors.redSoft;
                    fg = ok ? AppColors.primaryDark : AppColors.red;
                  } else {
                    bg = AppColors.primarySoft;
                    fg = AppColors.primaryDark;
                  }
                } else if (s.isLocked(q)) {
                  bg = AppColors.redSoft;
                  fg = AppColors.red;
                }
                return GestureDetector(
                  onTap: forced ? null : () => _goTo(i),
                  child: Container(
                    width: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cur ? AppColors.primary : Colors.transparent, width: 2),
                    ),
                    child: Text('${i + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(QuizQuestion q, int i) {
    final o = q.options[i];
    final letter = answerLetters[i];
    final mine = s.answers[q.id];
    final selected = mine == o.original;
    final reveal = s.instantFeedback && (s.isAnswered(q) || s.isLocked(q));
    final isCorrect = o.original == q.correct;

    Color border = AppColors.border, bg = AppColors.surface, badgeBg = AppColors.background, badgeFg = AppColors.textMuted;
    IconData? icon;
    if (reveal && isCorrect) {
      border = AppColors.primary;
      bg = AppColors.primarySoft;
      badgeBg = AppColors.primary;
      badgeFg = Colors.white;
      icon = Iconsax.tick_circle;
    } else if (reveal && selected) {
      border = AppColors.red;
      bg = AppColors.redSoft;
      badgeBg = AppColors.red;
      badgeFg = Colors.white;
      icon = Iconsax.close_circle;
    } else if (selected) {
      border = AppColors.primary;
      bg = AppColors.primarySoft;
      badgeBg = AppColors.primary;
      badgeFg = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: s.canAnswer(q) ? () => _select(q, o) : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
                  child: icon != null
                      ? Icon(icon, color: badgeFg, size: 20)
                      : Text(letter, style: TextStyle(color: badgeFg, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(o.text, style: const TextStyle(fontSize: 15.5, height: 1.3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
