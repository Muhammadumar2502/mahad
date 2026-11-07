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
    return Scaffold(
      appBar: AppBar(title: const Text('Mening natijalarim')),
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
            color: AppColors.primary,
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _summary(list)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _chip('Hammasi (${all.length})', _kind == _Kind.all, () => setState(() => _kind = _Kind.all)),
                        _chip('Kitob (${count(ResultKind.book)})', _kind == _Kind.book, () => setState(() => _kind = _Kind.book)),
                        _chip('Aralash (${count(ResultKind.random)})', _kind == _Kind.random, () => setState(() => _kind = _Kind.random)),
                        _chip('Maxsus (${count(ResultKind.special)})', _kind == _Kind.special, () => setState(() => _kind = _Kind.special)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _chip('Barcha vaqt', _period == _Period.all, () => setState(() => _period = _Period.all), small: true),
                        _chip('7 kun', _period == _Period.week, () => setState(() => _period = _Period.week), small: true),
                        _chip('30 kun', _period == _Period.month, () => setState(() => _period = _Period.month), small: true),
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
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ResultTile(r: list[i]),
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
    final valid = list.where((r) => r.total > 0).toList();
    final avg = valid.isEmpty ? 0.0 : valid.map((r) => r.percent).reduce((a, b) => a + b) / valid.length;
    final best = valid.isEmpty ? 0.0 : valid.map((r) => r.percent).reduce((a, b) => a > b ? a : b);
    Widget cell(String label, String value, Color c) => Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              cell('Urinish', '${list.length}', AppColors.blue),
              cell("O'rtacha", formatPercent(double.parse(avg.toStringAsFixed(1))), percentColor(avg)),
              cell('Eng yaxshi', formatPercent(double.parse(best.toStringAsFixed(1))), percentColor(best)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {bool small = false}) => Padding(
    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
    child: ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: small ? 12.5 : 13.5)),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(color: selected ? AppColors.primaryDark : AppColors.text, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      onSelected: (_) => onTap(),
    ),
  );
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
