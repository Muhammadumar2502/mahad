import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../../widgets/theme_switch_tile.dart';
import '../auth/login_screen.dart';
import '../rate/rate_screen.dart';
import '../results/results_screen.dart';
import '../special/special_tests_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  GroupInfo? _group;
  DeviceRecord? _device;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([Session.group(force: true), Repo.myDevice()]);
      _group = r[0] as GroupInfo?;
      _device = r[1] as DeviceRecord?;
    } catch (_) {
      // Profil asosiy ma'lumoti lokalda bor — xato bo'lsa ham ko'rsatamiz.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Chiqish',
      message: "Akkauntdan chiqasizmi? Tugallanmagan testlar o'chadi.\nShu qurilmada qayta kirishingiz mumkin.",
      confirm: 'Chiqish',
      danger: true,
    );
    if (!ok || !mounted) return;
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final u = Session.user;
    return RefreshIndicator(
      color: c.spinner,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          FadeSlideIn(
            child: DoubleFrame(
              shadow: true,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  StarMedallion(
                    size: 64,
                    tone: MedallionTone.emerald,
                    child: Text(
                      (u?.name.isNotEmpty ?? false) ? u!.name.characters.first.toUpperCase() : '?',
                      style: AppTheme.display(26, FontWeight.w700, 28, c.bandText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u?.name ?? '', style: AppTheme.display(25, FontWeight.w700, 29, c.ink)),
                        const SizedBox(height: 2),
                        Text(_formatPhone(u?.phone ?? ''), style: AppTheme.body(14, FontWeight.w400, 19, c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 1,
            child: _card([
              _row(Iconsax.people, 'Guruh', _loading && _group == null ? '...' : (_group?.name ?? 'Biriktirilmagan')),
              if (_group != null) _row(Iconsax.timer_1, 'Taymer', _group!.timingLabel),
            ]),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 2,
            child: _card([
              _nav(Iconsax.clipboard_tick, 'Mening natijalarim', () => _push(const ResultsScreen())),
              _nav(Iconsax.cup, 'Liderlar', () => _push(const RateScreen())),
              _nav(Iconsax.star, 'Maxsus testlar', () => _push(const SpecialTestsScreen())),
            ]),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(index: 3, child: _card([const ThemeSwitchTile()])),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 4,
            child: _card([
              _row(Iconsax.mobile, 'Qurilma', _device?.name ?? (_loading ? '...' : '—')),
              if (_device?.createdAt != null) _row(Iconsax.calendar_tick, "Ulangan", formatDate(_device!.createdAt!)),
              _row(Iconsax.info_circle, 'Ilova versiyasi', '${DeviceData.appVersion} (${DeviceData.buildNumber})'),
            ]),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Akkaunt faqat shu qurilmada ishlaydi. Boshqa telefonga o'tish uchun admin qurilmani o'chirib berishi kerak.",
              style: AppTheme.body(12.5, FontWeight.w400, 18, c.muted),
            ),
          ),
          const SizedBox(height: 18),
          MahadButton(kind: MahadButtonKind.danger, onPressed: _logout, icon: Iconsax.logout, label: 'Chiqish'),
        ],
      ),
    );
  }

  void _push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  Widget _card(List<Widget> children) => DoubleFrame(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const DashedLine(indent: 34),
          children[i],
        ],
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value) {
    final c = context.mc;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Row(
        children: [
          MIcon(icon, color: c.icon, size: 20),
          const SizedBox(width: 14),
          Text(label, style: AppTheme.body(14, FontWeight.w400, 19, c.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(14, FontWeight.w600, 19, c.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(IconData icon, String label, VoidCallback onTap) {
    final c = context.mc;
    return PressScale(
      scale: 0.98,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            children: [
              MIcon(icon, color: c.icon, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppTheme.body(15.5, FontWeight.w600, 21, c.ink))),
              MahadIcon(MahadIcons.chevronRight, size: 18, color: c.goldText),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPhone(String p) {
    final d = p.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('998')) {
      return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
    }
    return p;
  }
}
