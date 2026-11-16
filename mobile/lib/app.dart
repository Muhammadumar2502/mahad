import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/update_screen.dart';
import 'features/quiz/quiz_sync.dart';

class MahadApp extends StatefulWidget {
  const MahadApp({super.key});

  @override
  State<MahadApp> createState() => _MahadAppState();
}

class _MahadAppState extends State<MahadApp> {
  bool _handling = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final api = ApiClient.instance;
    api.onSessionExpired = _onSessionExpired;
    api.onUpgradeRequired = _onUpgradeRequired;
    // Ilova fondan qaytganda yuborilmagan natijalarni darhol yuborish.
    _lifecycle = AppLifecycleListener(onResume: QuizSync.run);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// 401: token eskirgan, qurilma bloklangan / faol emas / topilmadi.
  Future<void> _onSessionExpired(String message) async {
    if (_handling) return;
    _handling = true;
    QuizSync.stop();
    await Session.clear(expired: true);
    Session.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(initialMessage: message)),
      (_) => false,
    );
    _handling = false;
  }

  void _onUpgradeRequired(String message) {
    Session.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => UpdateScreen(message: message)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder:
          (context, mode, _) => MaterialApp(
            title: 'Mahad Test',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.kun,
            darkTheme: AppTheme.tun,
            themeMode: mode,
            navigatorKey: Session.navigatorKey,
            scaffoldMessengerKey: Session.messengerKey,
            // Juda katta tizim shriftida ham layout buzilmasin.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: mq.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.25,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child,
                ),
              );
            },
            home: const SplashScreen(),
          ),
    );
  }
}
