import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';

class RateScreen extends StatelessWidget {
  const RateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = Session.user?.id;
    final c = context.mc;
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.pageFlat,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: c.pageGradient),
          child: AsyncView<List<RateEntry>>(
            load: Repo.rating,
            refreshInterval: const Duration(seconds: 30),
            builder: (context, list, refresh) => RefreshIndicator(
              color: c.spinner,
              onRefresh: refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 200 - top,
                    toolbarHeight: (104 - top).clamp(56.0, 104.0),
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    leadingWidth: 76,
                    leading: Center(
                      child: BandIconButton(asset: MahadIcons.back, onPressed: () => Navigator.pop(context)),
                    ),
                    flexibleSpace: LayoutBuilder(
                      builder: (context, box) {
                        final minH = (104 - top).clamp(56.0, 104.0) + top;
                        final t = ((box.maxHeight - minH) / (200 - minH)).clamp(0.0, 1.0);
                        return BandBackground(
                          height: box.maxHeight,
                          child: Stack(
                            children: [
                              Positioned(
                                right: 22,
                                top: 50,
                                child: Opacity(opacity: 0.35 * t, child: MahadIcon(MahadIcons.trophy, size: 96, color: c.bandOrn)),
                              ),
                              Positioned(
                                left: -14,
                                bottom: 10,
                                child: Opacity(opacity: 0.22 * t, child: MahadIcon(MahadIcons.starOutline, size: 86, color: c.bandOrn)),
                              ),
                              Align(
                                alignment: Alignment(0, 0.15 + 0.45 * t),
                                child: Padding(
                                  padding: EdgeInsets.only(top: top * (1 - t)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Liderlar',
                                        style: AppTheme.display(24 + 14 * t, FontWeight.w700, 30 + 14 * t, c.bandText),
                                      ),
                                      if (t > 0.4) ...[const SizedBox(height: 4), Opacity(opacity: (t - 0.4) / 0.6, child: const Ornament())],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (list.isEmpty)
                    const SliverFillRemaining(child: EmptyView(title: "Reyting hali shakllanmagan", icon: Iconsax.cup))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => FadeSlideIn(index: i, child: _row(context, i + 1, list[i], list[i].studentId == me)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int rank, RateEntry e, bool isMe) {
    final c = context.mc;
    final medals = [
      [c.medalGoldStart, c.medalGoldEnd],
      [c.medalSilverStart, c.medalSilverEnd],
      [c.medalBronzeStart, c.medalBronzeEnd],
    ];
    final tone = e.average >= 80 ? PercentTone.ok : (e.average >= 60 ? PercentTone.warn : PercentTone.bad);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: c.ownBd, width: 1.5) : null,
      ),
      child: DoubleFrame(
        color: isMe ? c.ownBg : null,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: rank <= 3
                  ? ClipPath(
                      clipper: _StarClipper(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: medals[rank - 1])),
                        child: Center(child: MIcon(Iconsax.medal_star_copy, color: c.ink, size: 20)),
                      ),
                    )
                  : DecoratedBox(
                      decoration: ShapeDecoration(color: c.card, shape: octagonBorder(48, side: BorderSide(color: c.gold))),
                      child: Center(child: Text('$rank', style: AppTheme.display(20, FontWeight.w700, 22, c.ink))),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMe ? '${e.name} (siz)' : e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(15.5, FontWeight.w600, 21, c.ink),
                  ),
                  const SizedBox(height: 6),
                  Pill.tone(context, text: '${e.attempts} ta', tone: PillTone.gold, icon: Iconsax.clipboard_tick_copy),
                ],
              ),
            ),
            PercentBadge(text: formatPercent(double.parse(e.average.toStringAsFixed(1))), tone: tone, solid: true),
          ],
        ),
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => octagramPath(Offset.zero & size);

  @override
  bool shouldReclip(_StarClipper oldClipper) => false;
}
