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
    return BandPage(
      title: b.name,
      uppercase: true,
      body: AsyncView<List<SectionDetail>>(
        key: _view,
        load: _load,
        refreshInterval: const Duration(seconds: 60),
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Bu kitobda bo'limlar yo'q",
        emptyIcon: Iconsax.note_1,
        builder: (context, list, refresh) => RefreshIndicator(
          color: context.mc.spinner,
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              if (b.stepBlock) ...[FadeSlideIn(child: _info(b)), const SizedBox(height: 12)],
              FadeSlideIn(
                index: 1,
                child: DoubleFrame(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const DashedLine(),
                        _sectionTile(list[i], _lockOf(list, i)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(Book b) {
    final c = context.mc;
    return DoubleFrame(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          StarMedallion(
            size: 30,
            tone: MedallionTone.gold,
            child: Text('i', style: AppTheme.display(17, FontWeight.w700, 18, c.goldText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: "Bo'limlar ketma-ket ochiladi: keyingisiga o'tish uchun kamida "),
                  TextSpan(text: '${b.passingPercentage}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' natija kerak.'),
                ],
              ),
              style: AppTheme.body(13, FontWeight.w400, 19, c.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(SectionDetail s, ({bool locked, String reason}) lock) {
    final c = context.mc;
    final pass = widget.book.passingPercentage;
    final best = s.bestPercent;
    final tried = s.attempts.isNotEmpty;
    final passed = tried && best >= pass;
    final failed = tried && !passed;

    Color plate = c.ok, iconColor = c.okOn;
    IconData icon = Iconsax.book_1;
    if (lock.locked) {
      plate = c.cell;
      iconColor = c.cellText;
      icon = Iconsax.lock_1;
    } else if (failed) {
      plate = c.bad;
      iconColor = c.badOn;
    }

    return PressScale(
      scale: 0.98,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          if (lock.locked) {
            infoDialog(context, icon: Iconsax.lock_1, title: s.name, message: lock.reason);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SectionScreen(sectionId: s.id, title: s.name, passPercent: pass)),
          );
          _view.currentState?.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 46,
                decoration: ShapeDecoration(color: plate, shape: const MihrabBorder()),
                padding: const EdgeInsets.only(top: 10),
                child: Center(child: MIcon(icon, color: iconColor, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(15.5, FontWeight.w600, 21, lock.locked ? c.muted : c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.hasTest ? '${s.questionCount} ta test${tried ? ' · ${s.attempts.length} urinish' : ''}' : "Test qo'shilmagan",
                      style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (tried)
                PercentBadge(
                  text: formatPercent(double.parse(best.toStringAsFixed(1))),
                  tone: passed ? PercentTone.ok : PercentTone.bad,
                ),
              const SizedBox(width: 6),
              MahadIcon(MahadIcons.chevronRight, size: 18, color: lock.locked ? c.hair : c.goldText),
            ],
          ),
        ),
      ),
    );
  }
}
