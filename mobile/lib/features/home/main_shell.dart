import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
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

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Tab content fade-in on switch (IndexedStack keeps every tab's state).
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    // Yuborilmay qolgan natijalarni fonda yuborish (ochilganda + har daqiqa).
    QuizSync.start();
  }

  @override
  void dispose() {
    QuizSync.stop();
    _fade.dispose();
    super.dispose();
  }

  final _savedKey = GlobalKey<SavedTabState>();
  final _homeKey = GlobalKey<HomeTabState>();

  static const _titles = ['Asosiy', 'Kitoblar', 'Saqlanganlar', 'Profil'];

  /// Header band height on tab screens (title starts at 46).
  static const _band = 150.0;

  /// Asosiy / Kitoblar put their search field across the band edge.
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final fade = CurvedAnimation(parent: _fade, curve: Curves.easeOutCubic);
    Widget tab(int i, Widget child) => Padding(
      padding: EdgeInsets.only(top: i == 2 ? _band : _band - _overlap),
      child: child,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.pageFlat,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: c.pageGradient),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BandBackground(
                height: _band,
                child: Padding(
                  padding: const EdgeInsets.only(top: 46),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder:
                            (child, a) => FadeTransition(
                              opacity: a,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.25),
                                  end: Offset.zero,
                                ).animate(a),
                                child: child,
                              ),
                            ),
                        child: Text(
                          _titles[_index],
                          key: ValueKey(_index),
                          style: AppTheme.display(
                            36,
                            FontWeight.w600,
                            40,
                            c.bandText,
                          ).copyWith(letterSpacing: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Ornament(),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.015),
                    end: Offset.zero,
                  ).animate(fade),
                  child: IndexedStack(
                    index: _index,
                    children: [
                      tab(0, HomeTab(key: _homeKey)),
                      tab(1, const BooksTab()),
                      tab(2, SavedTab(key: _savedKey)),
                      tab(3, const ProfileTab()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(color: c.navBg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 1, color: c.bandLine),
              const SizedBox(height: 2),
              Container(height: 1, color: c.bandLine),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) {
                  if (i != _index) _fade.forward(from: 0);
                  setState(() => _index = i);
                  if (i == 2) _savedKey.currentState?.reload();
                  if (i == 0) _homeKey.currentState?.reloadBanner();
                },
                destinations: const [
                  NavigationDestination(
                    icon: MIcon(Iconsax.home_2),
                    selectedIcon: MIcon(Iconsax.home_2_copy),
                    label: 'Asosiy',
                  ),
                  NavigationDestination(
                    icon: MahadIcon(MahadIcons.books),
                    selectedIcon: MahadIcon(MahadIcons.books),
                    label: 'Kitoblar',
                  ),
                  NavigationDestination(
                    icon: MIcon(Iconsax.heart),
                    selectedIcon: MIcon(Iconsax.heart_copy),
                    label: 'Saqlanganlar',
                  ),
                  NavigationDestination(
                    icon: MIcon(Iconsax.profile_circle),
                    selectedIcon: MIcon(Iconsax.profile_circle_copy),
                    label: 'Profil',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
