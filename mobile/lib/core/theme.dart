// Theme entry point. The real theme lives in core/theme/ (G · Klassik Islomiy, Kun + Tun).
// `AppColors` keeps its old names so existing screens compile; every constant now resolves to the
// active MahadColors token (Kun or Tun). Screens migrate to `context.mc` during the redesign.
import 'package:flutter/material.dart';

import 'theme/mahad_colors.dart';
import 'theme/theme_controller.dart';

export 'theme/app_theme.dart';
export 'theme/mahad_colors.dart';
export 'theme/theme_controller.dart';

class AppColors {
  AppColors._();

  static MahadColors get _c => ThemeController.instance.isDark ? MahadColors.tun : MahadColors.kun;

  static Color get primary => _c.icon;
  static Color get primaryDark => _c.okText;
  static Color get primarySoft => _c.okSoft;
  static Color get background => _c.pageFlat;
  static Color get surface => _c.card;
  static Color get text => _c.ink;
  static Color get textMuted => _c.muted;
  static Color get border => _c.frame;
  static Color get red => _c.bad;
  static Color get redSoft => _c.badSoft;
  static Color get orange => _c.warn;
  static Color get orangeSoft => _c.warnSoft;
  static Color get blue => _c.info;
  static Color get blueSoft => _c.infoSoft;
  static Color get gold => _c.gold;
}
