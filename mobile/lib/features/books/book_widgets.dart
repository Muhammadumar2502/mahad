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
    final c = context.mc;
    final locked = book.fullBlock;
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: DoubleFrame(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ArchPlate(
                      width: 92,
                      height: 108,
                      child: Opacity(opacity: locked ? 0.45 : 1, child: NetImage(path: book.image, fit: BoxFit.contain)),
                    ),
                    if (locked)
                      Positioned(
                        bottom: 8,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: ShapeDecoration(color: c.card, shape: octagonBorder(40, side: BorderSide(color: c.frame))),
                          child: Center(child: MIcon(Iconsax.lock_1, color: c.muted, size: 20)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  book.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(17.5, FontWeight.w700, 21, locked ? c.muted : c.ink).copyWith(letterSpacing: 1.1),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locked) ...[MIcon(Iconsax.lock_1, size: 13, color: c.muted), const SizedBox(width: 4)],
                    Text(
                      locked ? 'Yopiq' : "${book.sections.length} ta bo'lim",
                      style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted),
                    ),
                  ],
                ),
              ],
            ),
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
    infoDialog(
      context,
      icon: Iconsax.lock_1,
      title: 'Kitob yopiq',
      message: "Bu kitob hozircha admin tomonidan yopilgan. Ochilganda testlarni ishlay olasiz.",
    );
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
}
