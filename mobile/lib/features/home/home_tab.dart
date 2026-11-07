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
import '../rate/rate_screen.dart';
import '../special/special_tests_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final _search = TextEditingController();
  final _view = GlobalKey<AsyncViewState<List<Subject>>>();
  QuizSession? _unfinished;
  int _activeSpecial = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    reloadBanner();
    _loadSpecialCount();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _unfinished?.deadline != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _search.dispose();
    super.dispose();
  }

  void reloadBanner() {
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
        final q = _search.text.trim().toLowerCase();
        final shown = q.isEmpty ? subjects : subjects.where((s) => s.name.toLowerCase().contains(q)).toList();
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_unfinished != null) SliverToBoxAdapter(child: _banner(_unfinished!)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Fan qidirish',
                          fillColor: AppColors.surface,
                          prefixIcon: const Icon(Iconsax.search_normal_1, color: AppColors.primary),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Iconsax.close_circle),
                                  onPressed: () => setState(_search.clear),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'Liderlar',
                              icon: Iconsax.cup_copy,
                              colors: const [Color(0xFFFF9A3C), Color(0xFFFFB25E)],
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RateScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionButton(
                              label: 'Maxsus',
                              icon: Iconsax.star_1,
                              colors: const [Color(0xFF4CAF6E), Color(0xFF6CC28A)],
                              badge: _activeSpecial,
                              onTap: () => _afterReturn(
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialTestsScreen())),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _subjectCard(shown[i]),
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
    final rem = s.totalRemaining;
    final subtitle = s.isFinished
        ? 'Natija yuborilmagan — yuboring'
        : rem != null
            ? 'Qolgan vaqt: ${formatDuration(rem)}'
            : '${s.title} · ${s.answeredCount}/${s.total} javob';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF53B175), Color(0xFF6979F8)]),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Iconsax.clock, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tugallanmagan test', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _afterReturn(QuizLauncher.open(context, s)),
            child: const Text('Davom et'),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            height: 56,
            decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text('$badge', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _subjectCard(Subject s) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _afterReturn(
          Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectBooksScreen(subject: s))),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: NetImage(path: s.image, fallbackIcon: Iconsax.teacher),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
