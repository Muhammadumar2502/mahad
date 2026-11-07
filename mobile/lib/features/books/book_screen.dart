import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'section_screen.dart';

/// Kitob bo'limlari. Blok mantiqi backend (/section/:id) bilan bir xil:
/// stepBlock bo'lsa, oldingi bo'limning ENG YAXSHI natijasi passingPercentage dan
/// past bo'lsa keyingisi yopiq (oldingi bo'limda test bo'lmasa — ochiq).
class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _view = GlobalKey<AsyncViewState<List<SectionDetail>>>();

  Future<List<SectionDetail>> _load() async {
    final all = await Repo.sectionsAll();
    return all.where((s) => s.bookId == widget.book.id).toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  ({bool locked, String reason}) _lockOf(List<SectionDetail> list, int i) {
    final b = widget.book;
    if (b.fullBlock) return (locked: true, reason: 'Kitob yopiq');
    if (!b.stepBlock || i == 0) return (locked: false, reason: '');
    final prev = list[i - 1];
    if (!prev.hasTest) return (locked: false, reason: '');
    if (prev.attempts.isEmpty) {
      return (locked: true, reason: "Oldingi bo'limni (${prev.name}) tugatishingiz kerak");
    }
    if (prev.bestPercent < b.passingPercentage) {
      return (
        locked: true,
        reason: "Oldingi bo'limni kamida ${b.passingPercentage}% bilan tugating. "
            "Eng yaxshi natijangiz: ${formatPercent(prev.bestPercent)}",
      );
    }
    return (locked: false, reason: '');
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    return Scaffold(
      appBar: AppBar(title: Text(b.name)),
      body: AsyncView<List<SectionDetail>>(
        key: _view,
        load: _load,
        refreshInterval: const Duration(seconds: 60),
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Bu kitobda bo'limlar yo'q",
        emptyIcon: Iconsax.note_1,
        builder: (context, list, refresh) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) return _info(b);
              final idx = i - 1;
              return _sectionTile(list[idx], _lockOf(list, idx));
            },
          ),
        ),
      ),
    );
  }

  Widget _info(Book b) {
    if (!b.stepBlock) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Bo'limlar ketma-ket ochiladi: keyingisiga o'tish uchun kamida ${b.passingPercentage}% natija kerak.",
              style: const TextStyle(color: AppColors.blue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(SectionDetail s, ({bool locked, String reason}) lock) {
    final pass = widget.book.passingPercentage;
    final best = s.bestPercent;
    final tried = s.attempts.isNotEmpty;
    final passed = tried && best >= pass;
    final failed = tried && !passed;

    Color accent = AppColors.primary, soft = AppColors.primarySoft;
    IconData icon = Iconsax.book_1;
    if (lock.locked) {
      accent = AppColors.textMuted;
      soft = const Color(0xFFF0F1F3);
      icon = Iconsax.lock_1;
    } else if (failed) {
      accent = AppColors.red;
      soft = AppColors.redSoft;
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (lock.locked) {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                icon: const Icon(Iconsax.lock_1, size: 34, color: AppColors.textMuted),
                title: Text(s.name),
                content: Text(lock.reason),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tushunarli'))],
              ),
            );
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SectionScreen(sectionId: s.id, title: s.name, passPercent: pass)),
          );
          _view.currentState?.refresh();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lock.locked ? AppColors.border : accent.withValues(alpha: 0.35), width: 1.3),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lock.locked ? AppColors.textMuted : AppColors.text)),
                    const SizedBox(height: 3),
                    Text(
                      s.hasTest ? '${s.questionCount} ta test${tried ? ' · ${s.attempts.length} urinish' : ''}' : "Test qo'shilmagan",
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (tried)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: passed ? AppColors.primarySoft : AppColors.redSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    formatPercent(double.parse(best.toStringAsFixed(1))),
                    style: TextStyle(fontWeight: FontWeight.w700, color: passed ? AppColors.primaryDark : AppColors.red),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Iconsax.arrow_right_3, color: lock.locked ? AppColors.border : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
