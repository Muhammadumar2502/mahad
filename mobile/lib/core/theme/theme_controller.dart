// NEW FEATURE (requested by the product owner): "Tungi rejim" switch in ProfileTab.
// Stores the choice locally with get_storage (already used by the app). Default = Kun (light),
// so behaviour is unchanged until the user flips the switch.
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(_read());

  static final ThemeController instance = ThemeController._();
  static const String _key = 'theme_mode';

  static ThemeMode _read() {
    final saved = GetStorage().read<String>(_key);
    return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => value == ThemeMode.dark;

  void setDark(bool dark) {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    GetStorage().write(_key, dark ? 'dark' : 'light');
  }
}

/* Wiring in app.dart (only the MaterialApp theme arguments change; routes, observers,
   onSessionExpired / onUpgradeRequired handlers stay exactly as they are):

  ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeController.instance,
    builder: (context, mode, _) => MaterialApp(
      // ...existing arguments unchanged...
      theme: AppTheme.kun,
      darkTheme: AppTheme.tun,
      themeMode: mode,
    ),
  );

  GetStorage.init() must already run before runApp (it does today for sessions).
*/
