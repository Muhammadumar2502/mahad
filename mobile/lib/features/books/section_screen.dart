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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: AsyncView<SectionDetail>(
        key: _view,
        load: () => Repo.section(widget.sectionId),
        refreshInterval: const Duration(seconds: 60),
        builder: (context, s, refresh) {
          final pending = s.testId == null ? null : QuizSession.load(QuizLauncher.bookKey(s.testId!));
          final pass = s.book?.passingPercentage ?? widget.passPercent ?? 60;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Container(
                  height: 170,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                    child: Icon(Iconsax.book_1, color: AppColors.primary, size: 56),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              'Jami: ${s.questionCount} ta${s.bookName != null ? '  ·  ${s.bookName}' : ''}',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F1F3)),
                        onPressed: () => _toggleSave(s),
                        icon: Icon(
                          _isSaved ? Iconsax.heart_copy : Iconsax.heart,
                          color: _isSaved ? AppColors.red : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.isBlocked)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Icon(Iconsax.lock_1, color: AppColors.red),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.blockReason, style: TextStyle(color: AppColors.red))),
                        ],
                      ),
                    ),
                  ),
                if (s.attempts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        const Text('Urinishlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('Eng yaxshi: ${formatPercent(double.parse(s.bestPercent.toStringAsFixed(1)))}',
                            style: TextStyle(color: percentColor(s.bestPercent, pass: pass), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (pending != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _attemptTile(
                      icon: Iconsax.clipboard_text,
                      color: AppColors.orange,
                      title: 'Tugallanmagan',
                      trailing: '${pending.answeredCount}/${pending.total}',
                      onTap: () => _start(s),
                    ),
                  ),
                for (final a in s.attempts)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _attemptTile(
                      icon: Iconsax.tick_circle,
                      color: percentColor(s.questionCount == 0 ? 0 : a.solved * 100 / s.questionCount, pass: pass),
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
                  ),
                const SizedBox(height: 24),
                if (s.hasTest && !s.isBlocked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _start(s),
                          icon: Icon(pending != null ? Iconsax.play : Iconsax.document_text),
                          label: Text(pending != null ? 'Davom ettirish' : 'Testni boshlash'),
                        ),
                        if (pending != null) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(onPressed: () => _start(s, restart: true), child: const Text('Yangidan boshlash')),
                        ],
                      ],
                    ),
                  )
                else if (!s.hasTest)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: EmptyView(title: "Bu bo'limga hali test qo'shilmagan", icon: Iconsax.timer),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _attemptTile({
    required IconData icon,
    required Color color,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15.5))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(trailing, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 4),
              Icon(Iconsax.arrow_right_3, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
