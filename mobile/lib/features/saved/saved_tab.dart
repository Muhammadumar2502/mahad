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
    final c = context.mc;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final it = items[i];
        final id = asInt(it['id']) ?? 0;
        return FadeSlideIn(
          index: i,
          child: Dismissible(
            key: ValueKey(id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              decoration: BoxDecoration(
                color: c.badSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.bad.withValues(alpha: 0.4)),
              ),
              child: MIcon(Iconsax.trash, color: c.bad, size: 22),
            ),
            onDismissed: (_) async {
              final s = Storage.saved..remove('$id');
              await Storage.setSaved(s);
              reload();
            },
            child: PressScale(
              scale: 0.98,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectionScreen(sectionId: id, title: asStr(it['name']), passPercent: asInt(it['pass'])),
                      ),
                    );
                    reload();
                  },
                  child: DoubleFrame(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: ShapeDecoration(color: c.badSoft, shape: octagonBorder(44, side: BorderSide(color: c.bad.withValues(alpha: 0.4)))),
                          child: Center(child: MIcon(Iconsax.heart_copy, color: c.bad, size: 20)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asStr(it['name'], "Bo'lim"), style: AppTheme.display(21, FontWeight.w700, 25, c.ink)),
                              const SizedBox(height: 2),
                              Text(
                                [if (asStr(it['book']).isNotEmpty) asStr(it['book']), '${asInt(it['count']) ?? 0} ta test'].join(' · '),
                                style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted),
                              ),
                            ],
                          ),
                        ),
                        MahadIcon(MahadIcons.chevronRight, size: 18, color: c.goldText),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
