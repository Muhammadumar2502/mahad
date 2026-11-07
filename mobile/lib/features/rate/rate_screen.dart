import 'package:flutter/material.dart';
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
    return Scaffold(
      body: AsyncView<List<RateEntry>>(
        load: Repo.rating,
        refreshInterval: const Duration(seconds: 30),
        builder: (context, list, refresh) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 170,
                backgroundColor: const Color(0xFF4CAF6E),
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.25)),
                    icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 64, bottom: 16),
                  title: const Text('Liderlar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF4CAF6E), Color(0xFFB8A04A)]),
                    ),
                    child: Stack(
                      children: [
                        Positioned(right: -10, top: 10, child: Icon(Iconsax.cup_copy, size: 150, color: Colors.white.withValues(alpha: 0.15))),
                        Positioned(left: -20, bottom: -20, child: Icon(Iconsax.star_1, size: 120, color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(child: EmptyView(title: "Reyting hali shakllanmagan", icon: Iconsax.cup))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _row(i + 1, list[i], list[i].studentId == me),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(int rank, RateEntry e, bool isMe) {
    const medals = [Color(0xFFFFD000), Color(0xFFBDBDBD), Color(0xFFCD8B4A)];
    final chip = e.average >= 80 ? AppColors.primary : (e.average >= 60 ? AppColors.orange : AppColors.red);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFDDF1E3) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? const Color(0xFF9BD3AE) : AppColors.border, width: isMe ? 1.5 : 1),
      ),
      child: Row(
        children: [
          if (rank <= 3)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: medals[rank - 1],
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: medals[rank - 1].withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Iconsax.medal_star_copy, color: Colors.white, size: 30),
            )
          else
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBE8D4), width: 2),
              ),
              child: Text('$rank', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${e.name} (siz)' : e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Pill(text: '${e.attempts} ta', color: AppColors.primaryDark, background: AppColors.primarySoft, icon: Iconsax.clipboard_tick_copy),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: chip, borderRadius: BorderRadius.circular(10)),
            child: Text(
              formatPercent(double.parse(e.average.toStringAsFixed(1))),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
