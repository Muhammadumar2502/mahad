import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../quiz/review.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mening natijalarim')),
      body: AsyncView<List<ResultRecord>>(
        load: Repo.results,
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Hali natijalar yo'q",
        emptySubtitle: 'Birinchi testni ishlang — natija shu yerda chiqadi',
        emptyIcon: Iconsax.document_text,
        builder: (context, list, refresh) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ResultTile(r: list[i]),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.r});

  final ResultRecord r;

  @override
  Widget build(BuildContext context) {
    final (List<Color> grad, IconData icon, String? tag, Color tagColor) = switch (r.kind) {
      ResultKind.special => (const [Color(0xFF9C27B0), Color(0xFFBA68C8)], Iconsax.star_1, 'MAXSUS TEST', const Color(0xFF9C27B0)),
      ResultKind.random => (const [Color(0xFFFF9A3C), Color(0xFFFFB25E)], Iconsax.shuffle, 'ARALASH TEST', AppColors.orange),
      ResultKind.book => (const [Color(0xFF4CAF6E), Color(0xFF7CC896)], Iconsax.book_1, null, AppColors.primary),
    };
    final good = r.percent >= 60;
    final scoreColor = good ? AppColors.primary : AppColors.red;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final data = ReviewData.fromRecord(r);
          if (data == null) {
            Session.toast("Bu natija uchun batafsil javoblar saqlanmagan");
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(title: r.title, data: data)));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scoreColor.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: grad.first.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(tag, style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (r.subtitle != null && r.kind == ResultKind.book) ...[
                          const Icon(Iconsax.book, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(r.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          ),
                        ] else ...[
                          const Icon(Iconsax.message_question, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('${r.total} savol', style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                        ],
                        const SizedBox(width: 10),
                        const Icon(Iconsax.calendar_1, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(_short(r.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: scoreColor, borderRadius: BorderRadius.circular(8)),
                    child: Text('${r.solved}/${r.total}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _short(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    return d.year == now.year ? '${two(d.day)}.${two(d.month)}' : '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}
