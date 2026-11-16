import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'book_screen.dart';
import 'book_widgets.dart';

class BooksTab extends StatefulWidget {
  const BooksTab({super.key});

  @override
  State<BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<BooksTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Book>>(
      load: Repo.books,
      isEmpty: (b) => b.isEmpty,
      emptyTitle: "Kitoblar hali qo'shilmagan",
      emptyIcon: Iconsax.book_1,
      builder: (context, books, refresh) {
        final q = _search.text.trim().toLowerCase();
        final shown = q.isEmpty ? books : books.where((b) => b.name.toLowerCase().contains(q)).toList();
        return RefreshIndicator(
          color: context.mc.spinner,
          onRefresh: refresh,
          child: BooksGrid(
            books: shown,
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: MahadSearchField(
                controller: _search,
                hint: 'Kitob qidirish',
                onChanged: (_) => setState(() {}),
                onClear: () => setState(_search.clear),
              ),
            ),
            onTap: (b) => openBook(context, b, () => BookScreen(book: b)),
          ),
        );
      },
    );
  }
}
