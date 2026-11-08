// NEW (the only new feature): "Tungi rejim" row for ProfileTab, in its own DoubleFrame card
// between the navigation card and the device card (screens/kun|tun/51_profil.jpg).
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/mahad_colors.dart';
import '../core/theme/theme_controller.dart';
import 'mahad_icons.dart';

class ThemeSwitchTile extends StatelessWidget {
  const ThemeSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        return MergeSemantics(
          child: Semantics(
            toggled: dark,
            child: InkWell(
              onTap: () => ThemeController.instance.setDark(!dark),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Row(
                  children: [
                    MahadIcon(MahadIcons.moon, size: 21, color: c.icon),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tungi rejim', style: AppTheme.body(15.5, FontWeight.w600, 21, c.ink)),
                          Text(dark ? 'Yoqilgan' : "O'chiq", style: AppTheme.body(12, FontWeight.w400, 16, c.muted)),
                        ],
                      ),
                    ),
                    _MoonSwitch(value: dark, onChanged: ThemeController.instance.setDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 52×30 track; the knob carries a crescent when ON.
class _MoonSwitch extends StatelessWidget {
  const _MoonSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value ? LinearGradient(colors: [c.primaryStart, c.primaryEnd]) : null,
          color: value ? null : c.card3,
          border: Border.all(color: value ? c.gold : c.goldDeep.withValues(alpha: 0.6)),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.card,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 1 : 0,
              child: Center(child: MahadIcon(MahadIcons.moon, size: 13, color: c.goldText)),
            ),
          ),
        ),
      ),
    );
  }
}
