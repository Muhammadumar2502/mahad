import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = book.fullBlock;
    return Material(
      color: locked ? const Color(0xFFF2F2F4) : AppColors.orangeSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: locked ? AppColors.border : AppColors.orange, width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Opacity(opacity: locked ? 0.45 : 1, child: NetImage(path: book.image)),
                    ),
                  ),
                  if (locked)
                    const Positioned.fill(child: Center(child: Icon(Iconsax.lock_1, color: AppColors.textMuted, size: 34))),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                book.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                locked ? 'Yopiq' : "${book.sections.length} ta bo'lim",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BooksGrid extends StatelessWidget {
  const BooksGrid({super.key, required this.books, required this.onTap, this.header});

  final List<Book> books;
  final void Function(Book) onTap;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        if (books.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: 300, child: EmptyView(title: 'Kitob topilmadi', icon: Iconsax.book_1)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => BookCard(book: books[i], onTap: () => onTap(books[i])),
                childCount: books.length,
              ),
            ),
          ),
      ],
    );
  }
}

/// Kitob yopiq bo'lsa ogohlantiradi, aks holda ochadi.
void openBook(BuildContext context, Book book, Widget Function() page) {
  if (book.fullBlock) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Iconsax.lock_1, color: AppColors.textMuted, size: 36),
        title: const Text('Kitob yopiq'),
        content: const Text("Bu kitob hozircha admin tomonidan yopilgan. Ochilganda testlarni ishlay olasiz."),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tushunarli'))],
      ),
    );
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
}
