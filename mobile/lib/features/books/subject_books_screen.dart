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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(
            tooltip: 'Aralash test',
            icon: const Icon(Iconsax.shuffle, color: AppColors.primary),
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
      ),
      body: AsyncView<List<Book>>(
        load: _load,
        isEmpty: (b) => b.isEmpty,
        emptyTitle: "Bu fanda kitob yo'q",
        emptyIcon: Iconsax.book_1,
        builder: (context, books, refresh) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: BooksGrid(
            books: books,
            header: const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(colors: [Color(0xFF4CAF6E), Color(0xFF7CC896)]),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text("Kitoblar va bo'limlar", style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.25)),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              children: [
                for (final b in widget.books) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Checkbox(
                      tristate: true,
                      value: _bookState(b),
                      activeColor: AppColors.primary,
                      onChanged: (_) => _toggleBook(b),
                    ),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text("${b.sections.length} ta bo'lim"),
                    trailing: IconButton(
                      icon: Icon(_expanded.contains(b.id) ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1),
                      onPressed: () => setState(() => _expanded.contains(b.id) ? _expanded.remove(b.id) : _expanded.add(b.id)),
                    ),
                    onTap: () => _toggleBook(b),
                  ),
                  if (_expanded.contains(b.id))
                    for (final s in b.sections)
                      CheckboxListTile(
                        contentPadding: const EdgeInsets.only(left: 56, right: 16),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        value: _selected.contains(s.id),
                        title: Text(s.name),
                        secondary: _sectionCounts[s.id] == null
                            ? null
                            : Text('${_sectionCounts[s.id]} ta', style: const TextStyle(color: AppColors.textMuted)),
                        onChanged: (v) => setState(() => v == true ? _selected.add(s.id) : _selected.remove(s.id)),
                      ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBE8D4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Iconsax.task, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selected.isEmpty || _sectionCounts.isEmpty ? 'Test soni' : 'Test soni (mavjud: $_available)',
                              style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _count,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary),
                              decoration: const InputDecoration(
                                isDense: true,
                                fillColor: Color(0xFFF4FAF6),
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _valid ? _start : null,
                  icon: const Icon(Iconsax.play),
                  label: const Text('Testni boshlash'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
