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
    final c = context.mc;
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: c.pageFlat,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: c.pageGradient),
            child: Column(
              children: [
                BandBackground(
                  height: 104,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 44, 16, 0),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          BandIconButton(
                            asset: MahadIcons.close,
                            onPressed: sending ? null : () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTheme.display(21, FontWeight.w700, 24, c.bandText),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!s.isFinished)
                            ValueListenableBuilder<int>(valueListenable: _tick, builder: (_, _, _) => _timerChip())
                          else
                            const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: s.isFinished ? _submitView() : _quizView()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitView() {
    final c = context.mc;
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
            child: FadeSlideIn(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StarMedallion(icon: Iconsax.wifi_square, tone: MedallionTone.warn),
                  const SizedBox(height: 18),
                  Text(_submitError ?? '', textAlign: TextAlign.center, style: AppTheme.body(15.5, FontWeight.w500, 22, c.ink)),
                  const SizedBox(height: 8),
                  Text(
                    'Javoblaringiz saqlangan. $_retryIn s dan so\'ng avtomatik qayta yuboriladi.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(13.5, FontWeight.w400, 20, c.muted),
                  ),
                  const SizedBox(height: 22),
                  MahadButton(onPressed: _send, icon: Iconsax.refresh, label: 'Hozir yuborish'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Keyinroq (fonda yuboriladi)'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _timerChip() {
    final c = context.mc;
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
    if (secs == null) return const SizedBox(width: 44);
    final danger = secs <= (s.timing.hasPerQuestion && label == 'Savol' ? 5 : 60);
    final fg = danger ? c.badText : c.bandText;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: danger ? c.badSoft : c.bandBtnBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: danger ? c.bad.withValues(alpha: 0.5) : c.bandOrn.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MahadIcon(MahadIcons.hourglass, size: 15, color: danger ? c.bad : c.bandOrn),
          const SizedBox(width: 6),
          Text(
            '${label.isNotEmpty ? '$label ' : ''}${formatDuration(math.max(0, secs))}',
            style: AppTheme.body(14, FontWeight.w600, 18, fg).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }

  Widget _quizView() {
    final c = context.mc;
    final q = s.questions[s.current];
    final answered = s.isAnswered(q);
    final locked = s.isLocked(q);
    final isLast = s.current == s.total - 1;
    final forced = s.timing.forceNext;

    return Column(
      children: [
        _progressHeader(),
        if (s.timing.hasPerQuestion)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: ValueListenableBuilder<int>(
              valueListenable: _tick,
              builder: (_, _, _) {
                final rem = s.questionRemaining(q);
                final full = s.timing.perQuestionSeconds!;
                final v = rem == null ? (answered ? 1.0 : 0.0) : (rem / full).clamp(0.0, 1.0);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: v),
                    duration: const Duration(milliseconds: 480),
                    builder: (_, val, _) => LinearProgressIndicator(
                      value: val,
                      minHeight: 4,
                      backgroundColor: c.progBg,
                      color: rem != null && rem <= 5 ? c.bad : c.info,
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
                child: KeyedSubtree(
                  key: ValueKey(s.current),
                  child: CornerFrame(
                    shadow: false,
                    radius: 12,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, margin: const EdgeInsets.only(left: 40), color: c.hair)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Savol ${s.current + 1} / ${s.total}'.toUpperCase(),
                                style: AppTheme.body(11.5, FontWeight.w700, 16, c.goldText).copyWith(letterSpacing: 2.3),
                              ),
                            ),
                            Expanded(child: Container(height: 1, margin: const EdgeInsets.only(right: 40), color: c.hair)),
                          ],
                        ),
                        if (forced || (locked && !answered)) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: forced && !(locked && !answered)
                                ? Pill.tone(context, text: "Majburiy o'tish", tone: PillTone.gold, icon: Iconsax.arrow_right_1)
                                : Pill.tone(context, text: 'Vaqt tugadi — javob berilmadi', tone: PillTone.bad, icon: Iconsax.timer_pause),
                          ),
                          if (forced && locked && !answered) ...[
                            const SizedBox(height: 6),
                            Center(child: Pill.tone(context, text: "Majburiy o'tish", tone: PillTone.gold, icon: Iconsax.arrow_right_1)),
                          ],
                        ],
                        const SizedBox(height: 12),
                        Text(q.text, style: AppTheme.body(18.5, FontWeight.w500, 29, c.ink)),
                        const SizedBox(height: 14),
                        for (var i = 0; i < q.options.length; i++) _optionTile(q, i),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: c.navBg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: c.bandLine),
                const SizedBox(height: 2),
                Container(height: 1, color: c.bandLine),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      if (!forced && s.current > 0) ...[
                        Expanded(
                          child: MahadButton(kind: MahadButtonKind.secondary, onPressed: () => _goTo(s.current - 1), label: 'Orqaga'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: MahadButton(key: const Key('quiz_next'), onPressed: _next, label: isLast ? 'Yakunlash' : 'Keyingisi'),
                      ),
                    ],
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
    final c = context.mc;
    final forced = s.timing.forceNext;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: s.total == 0 ? 0 : s.answeredCount / s.total),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(value: v, backgroundColor: c.progBg, color: c.progFg, minHeight: 3),
              ),
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.builder(
              controller: _grid,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              scrollDirection: Axis.horizontal,
              itemExtent: 44,
              itemCount: s.total,
              itemBuilder: (_, i) {
                final q = s.questions[i];
                final cur = i == s.current;
                var bg = c.cell, fg = c.cellText;
                var striped = false;
                if (s.isAnswered(q)) {
                  if (s.instantFeedback) {
                    final ok = s.answers[q.id] == q.correct;
                    bg = ok ? c.okSoft : c.badSoft;
                    fg = ok ? c.okText : c.badText;
                  } else {
                    bg = c.goldSoft;
                    fg = c.goldSoftText;
                  }
                } else if (s.isLocked(q)) {
                  bg = c.badSoft;
                  fg = c.badText;
                  striped = true;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: forced ? null : () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: ShapeDecoration(
                        color: bg,
                        shape: MihrabBorder(side: cur ? BorderSide(color: c.curRing, width: 2) : BorderSide.none),
                      ),
                      child: CustomPaint(
                        painter: striped ? _StripePainter(c.bad.withValues(alpha: 0.18)) : null,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(child: Text('${i + 1}', style: AppTheme.body(13.5, cur ? FontWeight.w700 : FontWeight.w600, 18, cur ? c.ink : fg))),
                        ),
                      ),
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
    final c = context.mc;
    final o = q.options[i];
    final letter = answerLetters[i];
    final selected = s.answers[q.id] == o.original;
    final reveal = s.instantFeedback && (s.isAnswered(q) || s.isLocked(q)) && q.correct.isNotEmpty;
    final isCorrect = o.original == q.correct;

    var border = c.optBd, bg = c.optBg, badgeBg = c.letterBg, badgeBd = c.letterBd, badgeFg = c.letterText, text = c.ink;
    var width = 1.0;
    var bold = false;
    String? mark;
    if (reveal && isCorrect) {
      border = c.ok;
      bg = c.okTint;
      badgeBg = c.ok;
      badgeBd = c.ok;
      badgeFg = c.okOn;
      text = c.okText;
      mark = MahadIcons.check;
      width = 1.5;
      bold = true;
    } else if (reveal && selected) {
      border = c.bad;
      bg = c.badTint;
      badgeBg = c.bad;
      badgeBd = c.bad;
      badgeFg = c.badOn;
      text = c.badText;
      mark = MahadIcons.close;
      width = 1.5;
      bold = true;
    } else if (selected) {
      border = c.selBd;
      bg = c.selBg;
      badgeBg = c.selBadge;
      badgeBd = c.selBadge;
      badgeFg = c.selBadgeText;
      text = c.selText;
      width = 1.5;
      bold = true;
    }

    return Padding(
      key: Key('quiz_opt_$i'),
      padding: const EdgeInsets.only(bottom: 10),
      child: PressScale(
        scale: 0.98,
        enabled: s.canAnswer(q),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: s.canAnswer(q) ? () => _select(q, o) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.fromLTRB(10, 11, 12, 11),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border, width: width)),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: ShapeDecoration(color: badgeBg, shape: octagonBorder(30, side: BorderSide(color: badgeBd))),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
                        child: mark != null
                            ? MahadIcon(mark, key: ValueKey(mark), size: 16, color: badgeFg)
                            : Text(letter, key: ValueKey(letter), style: AppTheme.display(16, FontWeight.w700, 18, badgeFg)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(o.text, style: AppTheme.body(15, bold ? FontWeight.w600 : FontWeight.w400, 22, text)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagonal stripes for timed-out question cells.
class _StripePainter extends CustomPainter {
  _StripePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(const MihrabBorder().getOuterPath(Offset.zero & size));
    final p = Paint()
      ..color = color
      ..strokeWidth = 4;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}
