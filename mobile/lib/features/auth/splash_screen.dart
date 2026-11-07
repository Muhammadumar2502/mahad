import 'package:flutter/material.dart';

import '../../core/device.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/splash_logo.png', width: 120),
            const SizedBox(height: 20),
            const Text(
              'Mahad Test',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
