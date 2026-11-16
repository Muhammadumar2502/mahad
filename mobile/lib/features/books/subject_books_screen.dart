import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/services.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_launcher.dart';
import 'book_screen.dart';
import 'book_widgets.dart';

class SubjectBooksScreen extends StatefulWidget {
  const SubjectBooksScreen({super.key, required this.subject});

  final Subject subject;

  @override
  State<SubjectBooksScreen> createState() => _SubjectBooksScreenState();
}

class _SubjectBooksScreenState extends State<SubjectBooksScreen> {
  List<Book> _books = const [];

  Future<List<Book>> _load() async {
    final all = await Repo.books();
    _books = all.where((b) => b.subjectId == widget.subject.id).toList();
    return _books;
  }

  @override
  Widget build(BuildContext context) {
    return BandPage(
      title: widget.subject.name,
      uppercase: true,
      actions: [
        BandIconButton(
          tooltip: 'Aralash test',
          icon: Iconsax.shuffle,
          onPressed: () {
            final open = _books.where((b) => !b.fullBlock && b.sections.isNotEmpty).toList();
            if (open.isEmpty) {
              Session.toast("Aralash test uchun ochiq kitob yo'q", error: true);
              return;
            }
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => RandomTestSheet(books: open),
            );
          },
        ),
      ],
      body: AsyncView<List<Book>>(
        load: _load,
        isEmpty: (b) => b.isEmpty,
        emptyTitle: "Bu fanda kitob yo'q",
        emptyIcon: Iconsax.book_1,
        builder: (context, books, refresh) => RefreshIndicator(
          color: context.mc.spinner,
          onRefresh: refresh,
          child: BooksGrid(
            books: books,
            header: const SizedBox(height: 14),
            onTap: (b) => openBook(context, b, () => BookScreen(book: b)),
          ),
        ),
      ),
    );
  }
}

/// "Kitoblar va bo'limlar" — aralash test sozlash oynasi.
class RandomTestSheet extends StatefulWidget {
  const RandomTestSheet({super.key, required this.books});

  final List<Book> books;

  @override
  State<RandomTestSheet> createState() => _RandomTestSheetState();
}

class _RandomTestSheetState extends State<RandomTestSheet> {
  final Set<int> _selected = {};
  final Set<int> _expanded = {};
  final _count = TextEditingController(text: '20');
  Map<int, int> _sectionCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final secs = await Repo.sectionsAll();
      if (!mounted) return;
      setState(() => _sectionCounts = {for (final s in secs) s.id: s.questionCount});
    } catch (_) {}
  }

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  int get _available => _selected.fold(0, (sum, id) => sum + (_sectionCounts[id] ?? 0));
  int get _wanted => int.tryParse(_count.text) ?? 0;
  bool get _valid => _selected.isNotEmpty && _wanted > 0 && (_sectionCounts.isEmpty || _available > 0);

  bool? _bookState(Book b) {
    final ids = b.sections.map((s) => s.id);
    final n = ids.where(_selected.contains).length;
    if (n == 0) return false;
    if (n == b.sections.length) return true;
    return null;
  }

  void _toggleBook(Book b) {
    setState(() {
      final all = _bookState(b) == true;
      for (final s in b.sections) {
        all ? _selected.remove(s.id) : _selected.add(s.id);
      }
    });
  }

  Future<void> _start() async {
    var count = _wanted;
    if (_sectionCounts.isNotEmpty && count > _available) count = _available;
    final nav = Navigator.of(context);
    final ctx = nav.context;
    nav.pop();
    await QuizLauncher.startRandom(ctx, sectionIds: _selected.toList(), count: count);
  }

  Widget _check(bool? value, VoidCallback onTap) {
    final c = context.mc;
    final on = value != false;
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: on ? c.checkOn : c.card,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: on ? c.checkOn : c.checkBd, width: 1.5),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: value == null
                ? Center(key: const ValueKey('m'), child: Container(width: 10, height: 2.4, color: c.checkMark))
                : value
                    ? MahadIcon(MahadIcons.check, key: const ValueKey('c'), size: 18, color: c.checkMark)
                    : const SizedBox.shrink(key: ValueKey('e')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: c.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BandBackground(
            height: 66,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Kitoblar va bo'limlar", style: AppTheme.display(24, FontWeight.w700, 28, c.bandText)),
                  ),
                  BandIconButton(asset: MahadIcons.close, onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              children: [
                for (final b in widget.books) ...[
                  InkWell(
                    onTap: () => _toggleBook(b),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      child: Row(
                        children: [
                          _check(_bookState(b), () => _toggleBook(b)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.name, style: AppTheme.body(15, FontWeight.w600, 20, c.ink)),
                                Text("${b.sections.length} ta bo'lim", style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted)),
                              ],
                            ),
                          ),
                          PressScale(
                            child: Material(
                              color: c.card,
                              shape: CircleBorder(side: BorderSide(color: c.frame)),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => setState(() => _expanded.contains(b.id) ? _expanded.remove(b.id) : _expanded.add(b.id)),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: Center(
                                    child: AnimatedRotation(
                                      turns: _expanded.contains(b.id) ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 220),
                                      child: MahadIcon(MahadIcons.chevronDown, size: 16, color: c.goldText),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        if (_expanded.contains(b.id))
                          for (final s in b.sections)
                            InkWell(
                              onTap: () => setState(() => _selected.contains(s.id) ? _selected.remove(s.id) : _selected.add(s.id)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(52, 9, 16, 9),
                                child: Row(
                                  children: [
                                    _check(_selected.contains(s.id), () => setState(() => _selected.contains(s.id) ? _selected.remove(s.id) : _selected.add(s.id))),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(s.name, style: AppTheme.body(14, FontWeight.w400, 19, c.ink))),
                                    if (_sectionCounts[s.id] != null)
                                      Text('${_sectionCounts[s.id]} ta', style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted).copyWith(letterSpacing: 0.6)),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: c.hair),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                DoubleFrame(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: ShapeDecoration(color: c.emerald, shape: octagonBorder(50, side: BorderSide(color: c.gold.withValues(alpha: 0.6)))),
                        child: Center(child: MIcon(Iconsax.task, color: c.bandText, size: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected.isEmpty || _sectionCounts.isEmpty ? 'Test soni' : 'Test soni (mavjud: $_available)',
                              style: AppTheme.body(12.5, FontWeight.w600, 17, c.muted),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _count,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                              onChanged: (_) => setState(() {}),
                              style: AppTheme.display(28, FontWeight.w700, 32, c.icon),
                              decoration: InputDecoration(
                                isDense: true,
                                fillColor: c.inputBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MahadButton(
                  onPressed: _valid ? _start : null,
                  icon: Iconsax.play,
                  label: 'Testni boshlash',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
