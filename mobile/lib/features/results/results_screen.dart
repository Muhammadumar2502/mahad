import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_sync.dart';
import '../quiz/review.dart';

enum _Kind { all, book, random, special }

enum _Period { all, week, month }

/// Mening natijalarim: tur va davr bo'yicha filtr, umumiy statistika,
/// fonda real vaqtda yangilanadi (yangi natija yuborilsa darhol chiqadi).
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  _Kind _kind = _Kind.all;
  _Period _period = _Period.all;
  final _view = GlobalKey<AsyncViewState<List<ResultRecord>>>();
  StreamSubscription<void>? _sync;

  @override
  void initState() {
    super.initState();
    _sync = QuizSync.changes.listen((_) => _view.currentState?.refresh());
  }

  @override
  void dispose() {
    _sync?.cancel();
    super.dispose();
  }

  List<ResultRecord> _apply(List<ResultRecord> all) {
    final now = DateTime.now();
    return all.where((r) {
      final kindOk = switch (_kind) {
        _Kind.all => true,
        _Kind.book => r.kind == ResultKind.book,
        _Kind.random => r.kind == ResultKind.random,
        _Kind.special => r.kind == ResultKind.special,
      };
      final periodOk = switch (_period) {
        _Period.all => true,
        _Period.week => now.difference(r.date).inDays < 7,
        _Period.month => now.difference(r.date).inDays < 30,
      };
      return kindOk && periodOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BandPage(
      title: 'Mening natijalarim',
      body: AsyncView<List<ResultRecord>>(
        key: _view,
        load: Repo.results,
        refreshInterval: const Duration(seconds: 60),
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Hali natijalar yo'q",
        emptySubtitle: 'Birinchi testni ishlang — natija shu yerda chiqadi',
        emptyIcon: Iconsax.document_text,
        builder: (context, all, refresh) {
          final list = _apply(all);
          int count(ResultKind k) => all.where((r) => r.kind == k).length;
          return RefreshIndicator(
            color: context.mc.spinner,
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: FadeSlideIn(child: _summary(list))),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        MahadChip(label: 'Hammasi (${all.length})', selected: _kind == _Kind.all, onTap: () => setState(() => _kind = _Kind.all)),
                        MahadChip(label: 'Kitob (${count(ResultKind.book)})', selected: _kind == _Kind.book, onTap: () => setState(() => _kind = _Kind.book)),
                        MahadChip(label: 'Aralash (${count(ResultKind.random)})', selected: _kind == _Kind.random, onTap: () => setState(() => _kind = _Kind.random)),
                        MahadChip(label: 'Maxsus (${count(ResultKind.special)})', selected: _kind == _Kind.special, onTap: () => setState(() => _kind = _Kind.special)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        MahadChip(label: 'Barcha vaqt', selected: _period == _Period.all, onTap: () => setState(() => _period = _Period.all), small: true),
                        MahadChip(label: '7 kun', selected: _period == _Period.week, onTap: () => setState(() => _period = _Period.week), small: true),
                        MahadChip(label: '30 kun', selected: _period == _Period.month, onTap: () => setState(() => _period = _Period.month), small: true),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(title: 'Bu filtr bo\'yicha natija yo\'q', icon: Iconsax.filter_remove),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _ResultTile(r: list[i])),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(List<ResultRecord> list) {
    final c = context.mc;
    final valid = list.where((r) => r.total > 0).toList();
    final avg = valid.isEmpty ? 0.0 : valid.map((r) => r.percent).reduce((a, b) => a + b) / valid.length;
    final best = valid.isEmpty ? 0.0 : valid.map((r) => r.percent).reduce((a, b) => a > b ? a : b);
    Widget cell(String label, String value, Color col) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: AppTheme.display(28, FontWeight.w700, 32, col)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.body(12, FontWeight.w500, 16, c.muted)),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: DoubleFrame(
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            children: [
              cell('Urinish', '${list.length}', c.info),
              VerticalDivider(width: 1, color: c.hair),
              cell("O'rtacha", formatPercent(double.parse(avg.toStringAsFixed(1))), percentColor(avg)),
              VerticalDivider(width: 1, color: c.hair),
              cell('Eng yaxshi', formatPercent(double.parse(best.toStringAsFixed(1))), percentColor(best)),
            ],
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
    final c = context.mc;
    final (List<Color> grad, IconData icon, String? tag, Color tagColor, Color tagBg) = switch (r.kind) {
      ResultKind.special => ([c.iconSpecialStart, c.iconSpecialEnd], Iconsax.star_1, 'MAXSUS TEST', c.purText, c.purSoft),
      ResultKind.random => ([c.iconMixStart, c.iconMixEnd], Iconsax.shuffle, 'ARALASH TEST', c.warnText, c.warnSoft),
      ResultKind.book => ([c.iconBookStart, c.iconBookEnd], Iconsax.book_1, null, c.okText, c.okSoft),
    };
    final good = r.percent >= 60;
    final scoreColor = good ? c.ok : c.bad;

    return PressScale(
      scale: 0.98,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scoreColor.withValues(alpha: 0.45))),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final data = ReviewData.fromRecord(r);
            if (data == null) {
              Session.toast("Bu natija uchun batafsil javoblar saqlanmagan");
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(title: r.title, data: data)));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 58,
                  decoration: ShapeDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: grad),
                    shape: MihrabBorder(side: BorderSide(color: c.gold.withValues(alpha: 0.6))),
                  ),
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(child: MIcon(icon, color: c.icOn, size: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                          child: Text(tag, style: AppTheme.body(10.5, FontWeight.w700, 14, tagColor).copyWith(letterSpacing: 1.2)),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.display(21, FontWeight.w700, 25, c.ink)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (r.subtitle != null && r.kind == ResultKind.book) ...[
                            MIcon(Iconsax.book, size: 14, color: c.muted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(r.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted)),
                            ),
                          ] else ...[
                            MIcon(Iconsax.message_question, size: 14, color: c.muted),
                            const SizedBox(width: 4),
                            Text('${r.total} savol', style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted)),
                          ],
                          const SizedBox(width: 10),
                          MIcon(Iconsax.calendar_1, size: 13, color: c.muted),
                          const SizedBox(width: 4),
                          Text(_short(r.date), style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PercentBadge(text: '${r.solved}/${r.total}', tone: good ? PercentTone.ok : PercentTone.bad, solid: true),
                    const SizedBox(height: 6),
                    MahadIcon(MahadIcons.chevronRight, size: 18, color: c.goldText),
                  ],
                ),
              ],
            ),
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
