import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../books/section_screen.dart';

class SavedTab extends StatefulWidget {
  const SavedTab({super.key});

  @override
  State<SavedTab> createState() => SavedTabState();
}

class SavedTabState extends State<SavedTab> {
  void reload() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = Storage.saved.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      ..sort((a, b) => asStr(b['savedAt']).compareTo(asStr(a['savedAt'])));

    if (items.isEmpty) {
      return const EmptyView(
        title: "Saqlanganlar yo'q",
        subtitle: "Bo'lim sahifasida ♡ tugmasini bosing — shu yerda paydo bo'ladi",
        icon: Iconsax.heart,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final it = items[i];
        final id = asInt(it['id']) ?? 0;
        return Dismissible(
          key: ValueKey(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Iconsax.trash, color: AppColors.red),
          ),
          onDismissed: (_) async {
            final s = Storage.saved..remove('$id');
            await Storage.setSaved(s);
            reload();
          },
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SectionScreen(sectionId: id, title: asStr(it['name']), passPercent: asInt(it['pass'])),
                  ),
                );
                reload();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.redSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.heart_copy, color: AppColors.red),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(asStr(it['name'], "Bo'lim"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(
                            [if (asStr(it['book']).isNotEmpty) asStr(it['book']), '${asInt(it['count']) ?? 0} ta test'].join(' · '),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Iconsax.arrow_right_3, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
