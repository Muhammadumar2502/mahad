import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../data/repository.dart';
import '../home/main_shell.dart';
import 'login_screen.dart';
import 'update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 900));

    // 1) Versiya: backenddagi APP_VERSION dan past bo'lsa — yangilash talab qilinadi.
    String? required;
    try {
      required = await Repo.serverVersion().timeout(const Duration(seconds: 6));
    } catch (_) {
      // Internet yo'q bo'lsa ham ilova ochilsin — ekranlar o'zi xatoni ko'rsatadi.
    }
    await minDelay;
    if (!mounted) return;

    if (required != null && DeviceData.compareVersions(DeviceData.appVersion, required) < 0) {
      _replace(UpdateScreen(requiredVersion: required));
      return;
    }

    // 2) Sessiya: token bo'lsa — ichkariga. Token/qurilma yaroqsiz bo'lsa,
    // birinchi so'rovdayoq 401 keladi va global handler login'ga qaytaradi.
    if (Session.isLoggedIn) {
      Session.group().ignore();
      _replace(const MainShell());
    } else {
      _replace(const LoginScreen());
    }
  }

  void _replace(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.bandEnd,
        body: BandBackground(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: FadeSlideIn(
              offset: 18,
              duration: const Duration(milliseconds: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo/seal_gold_1152.png', width: 168),
                  const SizedBox(height: 22),
                  Text('Mahad Test', style: AppTheme.display(40, FontWeight.w600, 44, c.bandText).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 6),
                  const Ornament(width: 30),
                  const SizedBox(height: 30),
                  MahadSpinner(size: 28, color: c.bandOrn, track: c.bandOrn.withValues(alpha: 0.25)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
