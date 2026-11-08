import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../books/subject_books_screen.dart';
import '../quiz/quiz_launcher.dart';
import '../quiz/quiz_session.dart';
import '../quiz/quiz_sync.dart';
import '../rate/rate_screen.dart';
import '../special/special_tests_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _view = GlobalKey<AsyncViewState<List<Subject>>>();
  QuizSession? _unfinished;
  int _activeSpecial = 0;
  Timer? _ticker;
  Timer? _specialTimer;
  StreamSubscription<void>? _syncSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reloadBanner();
    _loadSpecialCount();
    // Banner taymeri — real vaqtda; vaqt tugasa natija fonda yuboriladi.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final u = _unfinished;
      if (!mounted || u == null) return;
      if (!u.isFinished && u.isExpired) {
        QuizSync.run();
      }
      if (u.effectiveDeadline != null) setState(() {});
    });
    // Maxsus testlar soni — har daqiqada (yangi test ochilsa nishoncha chiqadi).
    _specialTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadSpecialCount());
    _syncSub = QuizSync.changes.listen((_) => reloadBanner());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _specialTimer?.cancel();
    _syncSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reloadBanner();
      _loadSpecialCount();
    }
  }

  void reloadBanner() {
    if (!mounted) return;
    setState(() => _unfinished = QuizLauncher.unfinished());
  }

  Future<void> _loadSpecialCount() async {
    try {
      final list = await Repo.specialTests();
      final now = ApiClient.instance.serverNow;
      if (!mounted) return;
      setState(() => _activeSpecial = list.where((t) => t.statusAt(now) == SpecialStatus.active).length);
    } catch (_) {}
  }

  Future<void> _refreshAll() async {
    reloadBanner();
    await Future.wait([_view.currentState?.refresh() ?? Future.value(), _loadSpecialCount()]);
  }

  Future<void> _afterReturn(Future<dynamic> nav) async {
    await nav;
    if (!mounted) return;
    reloadBanner();
    _loadSpecialCount();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Subject>>(
      key: _view,
      load: Repo.subjects,
      builder: (context, subjects, refresh) {
        final c = context.mc;
        final q = _search.text.trim().toLowerCase();
        final shown = q.isEmpty ? subjects : subjects.where((s) => s.name.toLowerCase().contains(q)).toList();
        return RefreshIndicator(
          color: c.spinner,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_unfinished != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  sliver: SliverToBoxAdapter(child: FadeSlideIn(child: _banner(_unfinished!))),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      MahadSearchField(
                        controller: _search,
                        hint: 'Fan qidirish',
                        onChanged: (_) => setState(() {}),
                        onClear: () => setState(_search.clear),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FadeSlideIn(
                              index: 1,
                              child: _actionButton(
                                label: 'Liderlar',
                                icon: Iconsax.cup_copy,
                                iconColor: c.goldText,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RateScreen())),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FadeSlideIn(
                              index: 2,
                              child: _actionButton(
                                label: 'Maxsus',
                                icon: Iconsax.star_1,
                                iconColor: c.icon,
                                badge: _activeSpecial,
                                onTap: () => _afterReturn(
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialTestsScreen())),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (shown.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: EmptyView(
                      title: subjects.isEmpty ? 'Fanlar hali qo\'shilmagan' : 'Hech narsa topilmadi',
                      icon: Iconsax.search_status,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FadeSlideIn(index: i + 3, child: _subjectCard(shown[i])),
                      childCount: shown.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _banner(QuizSession s) {
    final c = context.mc;
    final rem = s.totalRemaining;
    final subtitle = (s.isFinished || s.isExpired)
        ? 'Natija yuborilmoqda...'
        : rem != null
            ? '${s.title} · ${formatDuration(rem)}'
            : '${s.title} · ${s.answeredCount}/${s.total} javob';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 30, offset: const Offset(0, 16), spreadRadius: -20)],
      ),
      child: DoubleFrame(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            const StarMedallion(icon: Iconsax.clock, size: 44, tone: MedallionTone.soft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tugallanmagan test', style: AppTheme.display(21, FontWeight.w700, 25, c.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.body(13, FontWeight.w400, 18, c.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MahadButton(
              label: 'Davom et',
              height: 44,
              expand: false,
              onPressed: () => _afterReturn(QuizLauncher.open(context, s)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final c = context.mc;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PressScale(
          child: Material(
            color: c.card,
            shape: MihrabBorder(side: BorderSide(color: c.frame), shoulder: 0.42),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 118,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                        child: DecoratedBox(decoration: ShapeDecoration(shape: MihrabBorder(side: BorderSide(color: c.frameIn), shoulder: 0.42))),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.55),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MIcon(icon, color: iconColor, size: 24),
                          const SizedBox(height: 6),
                          Text(label, style: AppTheme.display(23, FontWeight.w700, 26, c.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: 10,
            top: 4,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                decoration: BoxDecoration(
                  color: c.badge,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.card, width: 2),
                ),
                child: Center(child: Text('$badge', textAlign: TextAlign.center, style: AppTheme.body(12, FontWeight.w700, 16, c.badgeText))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _subjectCard(Subject s) {
    final c = context.mc;
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _afterReturn(
            Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectBooksScreen(subject: s))),
          ),
          child: DoubleFrame(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ArchPlate(
                  width: 104,
                  height: 126,
                  color: c.subjectPlate,
                  child: NetImage(path: s.image, fallbackIcon: Iconsax.teacher),
                ),
                const SizedBox(height: 12),
                Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(22, FontWeight.w700, 26, c.ink).copyWith(letterSpacing: 2.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
