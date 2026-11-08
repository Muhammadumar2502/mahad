import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
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
    final u = Session.user;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4CAF6E), Color(0xFF7CC896)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    (u?.name.isNotEmpty ?? false) ? u!.name.characters.first.toUpperCase() : '?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_formatPhone(u?.phone ?? ''), style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card([
            _row(Iconsax.people, 'Guruh', _loading && _group == null ? '...' : (_group?.name ?? 'Biriktirilmagan')),
            if (_group != null) _row(Iconsax.timer_1, 'Taymer', _group!.timingLabel),
          ]),
          const SizedBox(height: 12),
          _card([
            _nav(Iconsax.clipboard_tick, 'Mening natijalarim', () => _push(const ResultsScreen())),
            _nav(Iconsax.cup, 'Liderlar', () => _push(const RateScreen())),
            _nav(Iconsax.star, 'Maxsus testlar', () => _push(const SpecialTestsScreen())),
          ]),
          const SizedBox(height: 12),
          _card([
            _row(Iconsax.mobile, 'Qurilma', _device?.name ?? (_loading ? '...' : '—')),
            if (_device?.createdAt != null) _row(Iconsax.calendar_tick, "Ulangan", formatDate(_device!.createdAt!)),
            _row(Iconsax.info_circle, 'Ilova versiyasi', '${DeviceData.appVersion} (${DeviceData.buildNumber})'),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "Akkaunt faqat shu qurilmada ishlaydi. Boshqa telefonga o'tish uchun admin qurilmani o'chirib berishi kerak.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: BorderSide(color: AppColors.redSoft, width: 1.5)),
            onPressed: _logout,
            icon: const Icon(Iconsax.logout),
            label: const Text('Chiqish'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  Widget _card(List<Widget> children) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 56),
          children[i],
        ],
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Text(value, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );

  Widget _nav(IconData icon, String label, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    trailing: const Icon(Iconsax.arrow_right_3),
    onTap: onTap,
  );

  static String _formatPhone(String p) {
    final d = p.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('998')) {
      return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
    }
    return p;
  }
}
