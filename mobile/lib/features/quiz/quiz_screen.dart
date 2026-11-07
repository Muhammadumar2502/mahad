import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/api_client.dart';
import '../../core/clock.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import 'quiz_result_screen.dart';
import 'quiz_session.dart';
import 'quiz_sync.dart';
import 'review.dart';

/// Test ishlash ekrani: kitob, aralash va maxsus testlar uchun umumiy.
/// Pop natijasi: `true` — natija yuborildi.
///
/// Taymerlar (hammasi server soati bo'yicha, AppClock):
///  * umumiy vaqt (guruh `fullTime` / maxsus `total_time`) — tugasa avtomatik yuboriladi;
///  * har savol vaqti (guruh `timeMinutes`(s) / maxsus `time_per_question`) — tugasa savol yopiladi;
///    `forceNext` bo'lsa keyingi savolga avtomatik o'tiladi, orqaga qaytib bo'lmaydi;
///  * qat'iy chegara — maxsus test faolligi tugashidan 20 s oldin avtomatik yuboriladi.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.session});

  final QuizSession session;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

enum _SubmitState { idle, sending, failed, rejected }

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  QuizSession get s => widget.session;

  Timer? _timer;
  final _tick = ValueNotifier<int>(0); // faqat taymer vidjetlari tinglaydi
  final _scroll = ScrollController();
  final _grid = ScrollController();

  _SubmitState _submit = _SubmitState.idle;
  String? _submitError;
  Timer? _retryTimer;
  int _retryIn = 0;
  int _retryAttempt = 0;

  bool _warnedTotal = false;
  int? _warnedQuestion;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    QuizSync.openKeys.add(s.key);
    if (s.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    } else {
      s.lockExpiredQuestions();
      s.enterCurrent();
      s.save();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _onTick());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTick();
        _scrollGridToCurrent();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    QuizSync.openKeys.remove(s.key);
    _timer?.cancel();
    _retryTimer?.cancel();
    _tick.dispose();
    _scroll.dispose();
    _grid.dispose();
    // Yuborilmay qolgan bo'lsa — fondagi sinxronlash davom ettiradi.
    if (s.isFinished) Future<void>.delayed(const Duration(seconds: 1), QuizSync.run);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onTick();
      if (_submit == _SubmitState.failed) _send();
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) s.save();
  }

  // =================== taymer ===================

  void _onTick() {
    if (!mounted || s.isFinished) return;

    // 1) Umumiy vaqt / qat'iy chegara
    if (s.isExpired) {
      _finish(
        auto: true,
        reason: s.endsByHardDeadline ? 'Test muddati tugayapti' : 'Test vaqti tugadi',
      );
      return;
    }
    final total = s.totalRemaining;
    if (total != null && total <= 60 && !_warnedTotal) {
      _warnedTotal = true;
      HapticFeedback.heavyImpact();
      _snack('Testga 1 daqiqa qoldi');
    }

    // 2) Savol vaqtlari (fonda o'tib ketganlari ham)
    if (s.timing.hasPerQuestion) {
      final cur = s.questions[s.current];
      final rem = s.questionRemaining(cur);
      if (rem != null && rem <= 3 && rem > 0 && _warnedQuestion != cur.id) {
        _warnedQuestion = cur.id;
        HapticFeedback.mediumImpact();
      }
      if (s.lockExpiredQuestions()) {
        s.save();
        HapticFeedback.heavyImpact();
        if (s.timing.forceNext && s.isLocked(s.questions[s.current])) {
          _advanceForced();
          return;
        }
        setState(() {});
      }
    }
    _tick.value++;
  }

  void _advanceForced() {
    final next = _nextOpen(from: s.current + 1);
    if (next == null) {
      _finish(auto: true, reason: 'Savollar tugadi');
    } else {
      _goTo(next);
    }
  }

  int? _nextOpen({required int from}) {
    for (var i = from; i < s.total; i++) {
      if (!s.isLocked(s.questions[i])) return i;
    }
    return null;
  }

  // =================== amallar ===================

  void _goTo(int index) {
    if (index < 0 || index >= s.total || s.isFinished) return;
    setState(() {
      s.current = index;
      s.enterCurrent();
    });
    s.save();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _scrollGridToCurrent();
  }

  void _scrollGridToCurrent() {
    if (!_grid.hasClients) return;
    const item = 44.0;
    final view = _grid.position.viewportDimension;
    final target = (s.current * item - view / 2 + item / 2).clamp(0.0, _grid.position.maxScrollExtent);
    _grid.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _select(QuizQuestion q, QuizOption o) {
    if (!s.canAnswer(q)) return;
    HapticFeedback.selectionClick();
    setState(() => s.answers[q.id] = o.original);
    s.save();
  }

  void _next() {
    final last = s.current >= s.total - 1;
    if (last) {
      _askFinish();
      return;
    }
    if (s.timing.forceNext) {
      final n = _nextOpen(from: s.current + 1);
      n == null ? _askFinish() : _goTo(n);
    } else {
      _goTo(s.current + 1);
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
    if (ok && mounted) _finish(auto: false);
  }

  /// Ustidagi dialog/sheet'larni yopadi — natija ekrani test o'rniga chiqishi uchun.
  void _closeOverlays() {
    final r = _route;
    if (r == null) return;
    Navigator.of(context).popUntil((route) => route == r);
  }

  Future<void> _finish({required bool auto, String? reason}) async {
    if (s.isFinished) return;
    _timer?.cancel();
    s.lockExpiredQuestions();
    s.finishedAt = AppClock.now();
    await s.save();
    if (!mounted) return;
    _closeOverlays();
    if (auto && reason != null) _snack('$reason — natija yuborilmoqda');
    setState(() {});
    await _send();
  }

  Future<void> _send() async {
    if (_submit == _SubmitState.sending || !mounted) return;
    _retryTimer?.cancel();
    setState(() {
      _submit = _SubmitState.sending;
      _submitError = null;
    });
    try {
      final r = await s.submit();
      final hasKey = r.key.values.any((v) => v.isNotEmpty);
      final review = hasKey ? ReviewData.fromSession(s, key: r.key) : null;
      await s.discard();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
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
      final retryable = e.isNetwork || (e.statusCode ?? 0) >= 500 || e.statusCode == 429;
      if (!retryable && e.statusCode != 401) {
        // Server qat'iy rad etdi (muddati o'tgan / allaqachon topshirilgan / test o'chirilgan).
        await s.discard();
        setState(() {
          _submit = _SubmitState.rejected;
          _submitError = e.message;
        });
        return;
      }
      _scheduleRetry(e.message);
    } catch (_) {
      if (mounted) _scheduleRetry("Natijani yuborib bo'lmadi");
    }
  }

  /// Internet/server xatosida avtomatik qayta urinish: 3, 6, 12, 24, 30 ... soniya.
  void _scheduleRetry(String message) {
    _retryAttempt++;
    _retryIn = math.min(30, 3 * math.pow(2, _retryAttempt - 1).toInt());
    setState(() {
      _submit = _SubmitState.failed;
      _submitError = message;
    });
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_retryIn <= 1) {
        t.cancel();
        _send();
      } else {
        setState(() => _retryIn--);
      }
    });
  }

  Future<bool> _confirmExit() async {
    if (s.isFinished) return true;
    return confirmDialog(
      context,
      title: 'Testdan chiqasizmi?',
      message: s.timing.isTimed || s.hardDeadline != null
          ? "Javoblaringiz saqlanadi, lekin vaqt to'xtamaydi. Vaqt tugasa natija avtomatik yuboriladi."
          : 'Javoblaringiz saqlanadi. Keyinroq shu yerdan davom ettirasiz.',
      confirm: 'Chiqish',
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    final sending = _submit == _SubmitState.sending;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || sending) return;
        if (s.isFinished && _submit != _SubmitState.rejected) {
          // Yuborilmagan natija qoladi — fonda yuboriladi.
          Navigator.of(context).pop(false);
          return;
        }
        if (await _confirmExit() && context.mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.close_circle),
            onPressed: sending ? null : () => Navigator.of(context).maybePop(),
          ),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            if (!s.isFinished) ValueListenableBuilder<int>(valueListenable: _tick, builder: (_, _, _) => _timerChip()),
            const SizedBox(width: 12),
          ],
        ),
        body: s.isFinished ? _submitView() : _quizView(),
      ),
    );
  }

  Widget _submitView() {
    switch (_submit) {
      case _SubmitState.idle:
      case _SubmitState.sending:
        return LoadingView(text: _retryAttempt > 0 ? 'Qayta yuborilmoqda...' : 'Natija yuborilmoqda...');
      case _SubmitState.rejected:
        return ErrorView(
          message: '${_submitError ?? 'Xatolik'}\nNatija qabul qilinmadi.',
          onRetry: () => Navigator.of(context).pop(false),
        );
      case _SubmitState.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
                  child: const Icon(Iconsax.wifi_square, color: AppColors.orange, size: 34),
                ),
                const SizedBox(height: 16),
                Text(_submitError ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text(
                  'Javoblaringiz saqlangan. $_retryIn s dan so\'ng avtomatik qayta yuboriladi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(onPressed: _send, icon: const Icon(Iconsax.refresh), label: const Text('Hozir yuborish')),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Keyinroq (fonda yuboriladi)'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _timerChip() {
    int? secs;
    var label = '';
    if (s.timing.hasPerQuestion) {
      secs = s.questionRemaining(s.questions[s.current]);
      label = 'Savol';
    }
    final total = s.totalRemaining;
    if (total != null && (secs == null || total < secs)) {
      secs = total;
      label = s.endsByHardDeadline ? 'Muddat' : '';
    }
    if (secs == null) return const SizedBox.shrink();
    final danger = secs <= (s.timing.hasPerQuestion && label == 'Savol' ? 5 : 60);
    final c = danger ? AppColors.red : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: danger ? AppColors.redSoft : AppColors.blueSoft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.timer_1, size: 16, color: c),
          const SizedBox(width: 4),
          Text(
            '${label.isNotEmpty ? '$label ' : ''}${formatDuration(math.max(0, secs))}',
            style: TextStyle(fontWeight: FontWeight.w700, color: c, fontFeatures: const [FontFeature.tabularFigures()]),
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
        if (s.timing.hasPerQuestion)
          ValueListenableBuilder<int>(
            valueListenable: _tick,
            builder: (_, _, _) {
              final rem = s.questionRemaining(q);
              final full = s.timing.perQuestionSeconds!;
              final v = rem == null ? (answered ? 1.0 : 0.0) : (rem / full).clamp(0.0, 1.0);
              return LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: AppColors.border,
                color: rem != null && rem <= 5 ? AppColors.red : AppColors.blue,
              );
            },
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              Row(
                children: [
                  Text(
                    'Savol ${s.current + 1} / ${s.total}',
                    style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (forced)
                    const Pill(text: "Majburiy o'tish", color: AppColors.orange, background: AppColors.orangeSoft, icon: Iconsax.arrow_right_1),
                ],
              ),
              const SizedBox(height: 10),
              Text(q.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35)),
              const SizedBox(height: 18),
              for (var i = 0; i < q.options.length; i++) _optionTile(q, i),
              if (locked && !answered)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Pill(text: 'Vaqt tugadi — javob berilmadi', color: AppColors.red, background: AppColors.redSoft, icon: Iconsax.timer_pause),
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
                  Expanded(child: OutlinedButton(onPressed: () => _goTo(s.current - 1), child: const Text('Orqaga'))),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(key: const Key('quiz_next'), onPressed: _next, child: Text(isLast ? 'Yakunlash' : 'Keyingisi')),
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
            child: ListView.builder(
              controller: _grid,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              scrollDirection: Axis.horizontal,
              itemExtent: 44,
              itemCount: s.total,
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
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: forced ? null : () => _goTo(i),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cur ? AppColors.primary : Colors.transparent, width: 2),
                      ),
                      child: Text('${i + 1}', style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                    ),
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
    final selected = s.answers[q.id] == o.original;
    final reveal = s.instantFeedback && (s.isAnswered(q) || s.isLocked(q)) && q.correct.isNotEmpty;
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
      key: Key('quiz_opt_$i'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: s.canAnswer(q) ? () => _select(q, o) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
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
