import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_launcher.dart';
import '../quiz/quiz_session.dart';
import '../quiz/review.dart';

class SectionScreen extends StatefulWidget {
  const SectionScreen({super.key, required this.sectionId, required this.title, this.passPercent});

  final int sectionId;
  final String title;
  final int? passPercent;

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  final _view = GlobalKey<AsyncViewState<SectionDetail>>();

  bool get _isSaved => Storage.saved.containsKey('${widget.sectionId}');

  Future<void> _toggleSave(SectionDetail s) async {
    final saved = Storage.saved;
    final key = '${s.id}';
    if (saved.containsKey(key)) {
      saved.remove(key);
    } else {
      saved[key] = {
        'id': s.id,
        'name': s.name,
        'book': s.book?.name ?? s.bookName,
        'count': s.questionCount,
        'pass': s.book?.passingPercentage ?? widget.passPercent ?? 60,
        'savedAt': DateTime.now().toIso8601String(),
      };
    }
    await Storage.setSaved(saved);
    setState(() {});
  }

  Future<void> _start(SectionDetail s, {bool restart = false}) async {
    if (restart) {
      final ok = await confirmDialog(
        context,
        title: 'Yangidan boshlaysizmi?',
        message: "Tugallanmagan urinishdagi javoblar o'chiriladi.",
        confirm: 'Boshlash',
        danger: true,
      );
      if (!ok || !mounted) return;
    }
    final done = await QuizLauncher.startBook(
      context,
      section: s,
      passPercent: s.book?.passingPercentage ?? widget.passPercent ?? 60,
      restart: restart,
    );
    if (!mounted) return;
    if (done) {
      _view.currentState?.refresh();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return BandPage(
      title: widget.title,
      body: AsyncView<SectionDetail>(
        key: _view,
        load: () => Repo.section(widget.sectionId),
        refreshInterval: const Duration(seconds: 60),
        builder: (context, s, refresh) {
          final pending = s.testId == null ? null : QuizSession.load(QuizLauncher.bookKey(s.testId!));
          final pass = s.book?.passingPercentage ?? widget.passPercent ?? 60;
          final rows = <Widget>[
            if (pending != null)
              _attemptTile(
                icon: Iconsax.clipboard_text,
                tone: PercentTone.warn,
                title: 'Tugallanmagan',
                trailing: '${pending.answeredCount}/${pending.total}',
                onTap: () => _start(s),
              ),
            for (final a in s.attempts)
              _attemptTile(
                icon: Iconsax.tick_circle,
                tone: percentTone(s.questionCount == 0 ? 0 : a.solved * 100 / s.questionCount, pass: pass),
                title: formatDate(a.date),
                trailing: '${a.solved}/${s.questionCount}',
                onTap: () {
                  final data = ReviewData.fromRecord(ResultRecord(
                    id: a.id,
                    kind: ResultKind.book,
                    solved: a.solved,
                    total: s.questionCount,
                    date: a.date,
                    title: s.name,
                    answers: a.answers,
                  ));
                  if (data == null) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(title: s.name, data: data)));
                },
              ),
          ];
          final showButtons = s.hasTest && !s.isBlocked;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: c.spinner,
                  onRefresh: refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      FadeSlideIn(child: _header(s)),
                      if (s.isBlocked) ...[
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          index: 1,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c.badTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.bad.withValues(alpha: 0.45)),
                            ),
                            child: Row(
                              children: [
                                MIcon(Iconsax.lock_1, color: c.bad, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(s.blockReason, style: AppTheme.body(13.5, FontWeight.w600, 20, c.badText))),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (s.attempts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
                          child: Row(
                            children: [
                              Text('Urinishlar', style: AppTheme.display(23, FontWeight.w700, 27, c.ink)),
                              const Spacer(),
                              Text(
                                'Eng yaxshi: ${formatPercent(double.parse(s.bestPercent.toStringAsFixed(1)))}',
                                style: AppTheme.body(13, FontWeight.w700, 18, percentColor(s.bestPercent, pass: pass)),
                              ),
                            ],
                          ),
                        )
                      else if (pending != null)
                        const SizedBox(height: 12),
                      if (rows.isNotEmpty)
                        FadeSlideIn(
                          index: 2,
                          child: DoubleFrame(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            child: Column(
                              children: [
                                for (var i = 0; i < rows.length; i++) ...[if (i > 0) const DashedLine(), rows[i]],
                              ],
                            ),
                          ),
                        ),
                      if (!s.hasTest)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: EmptyView(title: "Bu bo'limga hali test qo'shilmagan", icon: Iconsax.timer),
                        ),
                    ],
                  ),
                ),
              ),
              if (showButtons)
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
                          child: Column(
                            children: [
                              MahadButton(
                                onPressed: () => _start(s),
                                icon: pending != null ? Iconsax.play : Iconsax.document_text,
                                label: pending != null ? 'Davom ettirish' : 'Testni boshlash',
                              ),
                              if (pending != null) ...[
                                const SizedBox(height: 10),
                                MahadButton(
                                  kind: MahadButtonKind.secondary,
                                  onPressed: () => _start(s, restart: true),
                                  label: 'Yangidan boshlash',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(SectionDetail s) {
    final c = context.mc;
    final saved = _isSaved;
    return DoubleFrame(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 80,
            decoration: ShapeDecoration(color: c.okSoft, shape: MihrabBorder(side: BorderSide(color: c.frame))),
            padding: const EdgeInsets.only(top: 16),
            child: Center(child: MIcon(Iconsax.book_1, color: c.ok, size: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: AppTheme.display(25, FontWeight.w700, 29, c.ink)),
                const SizedBox(height: 3),
                Text(
                  'Jami: ${s.questionCount} ta${s.bookName != null ? '  ·  ${s.bookName}' : ''}',
                  style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted),
                ),
              ],
            ),
          ),
          PressScale(
            child: Material(
              color: saved ? c.badSoft : c.card,
              shape: octagonBorder(44, side: BorderSide(color: saved ? c.bad.withValues(alpha: 0.6) : c.frame)),
              child: InkWell(
                customBorder: octagonBorder(44),
                onTap: () => _toggleSave(s),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: child),
                      child: MIcon(
                        saved ? Iconsax.heart_copy : Iconsax.heart,
                        key: ValueKey(saved),
                        color: saved ? c.bad : c.muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attemptTile({
    required IconData icon,
    required PercentTone tone,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    final c = context.mc;
    final (fg, soft) = switch (tone) {
      PercentTone.ok => (c.okText, c.okSoft),
      PercentTone.warn => (c.warnText, c.warnSoft),
      PercentTone.bad => (c.badText, c.badSoft),
    };
    final mark = icon == Iconsax.tick_circle ? MahadIcon(MahadIcons.check, color: fg, size: 18) : MIcon(icon, color: fg, size: 18);
    return PressScale(
      scale: 0.98,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: ShapeDecoration(color: soft, shape: octagonBorder(40, side: BorderSide(color: fg.withValues(alpha: 0.35)))),
                child: Center(child: mark),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: AppTheme.body(15.5, FontWeight.w500, 21, c.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: ShapeDecoration(color: soft, shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(6))),
                child: Text(trailing, style: AppTheme.body(12.5, FontWeight.w700, 16, fg)),
              ),
              const SizedBox(width: 6),
              MahadIcon(MahadIcons.chevronRight, size: 18, color: c.goldText),
            ],
          ),
        ),
      ),
    );
  }
}
