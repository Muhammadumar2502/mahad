import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../books/books_tab.dart';
import '../profile/profile_tab.dart';
import '../saved/saved_tab.dart';
import 'home_tab.dart';
import '../quiz/quiz_sync.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Yuborilmay qolgan natijalarni fonda yuborish (ochilganda + har daqiqa).
    QuizSync.start();
  }

  @override
  void dispose() {
    QuizSync.stop();
    super.dispose();
  }
  final _savedKey = GlobalKey<SavedTabState>();
  final _homeKey = GlobalKey<HomeTabState>();

  static const _titles = ['Asosiy', 'Kitoblar', 'Saqlanganlar', 'Profil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(key: _homeKey),
          const BooksTab(),
          SavedTab(key: _savedKey),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
              color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
        child: NavigationBar(
          height: 66,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primarySoft,
          selectedIndex: _index,
          onDestinationSelected: (i) {
            setState(() => _index = i);
            if (i == 2) _savedKey.currentState?.reload();
            if (i == 0) _homeKey.currentState?.reloadBanner();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.home_2),
              selectedIcon: Icon(Iconsax.home_2_copy, color: AppColors.primary),
              label: 'Asosiy',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.book_1),
              selectedIcon: Icon(Iconsax.book_1, color: AppColors.primary),
              label: 'Kitoblar',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.heart),
              selectedIcon: Icon(Iconsax.heart_copy, color: AppColors.primary),
              label: 'Saqlanganlar',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.profile_circle),
              selectedIcon: Icon(Iconsax.profile_circle_copy, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
