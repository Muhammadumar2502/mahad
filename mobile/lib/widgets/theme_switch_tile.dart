// NEW: "Tungi rejim" row for ProfileTab (its own DoubleFrame card between the navigation card
// and the device card — see screens/kun/51_profil.jpg and screens/tun/51_profil.jpg).
import 'package:flutter/material.dart';

import '../core/theme/mahad_colors.dart';
import '../core/theme/theme_controller.dart';
import 'mahad_icons.dart';

class ThemeSwitchTile extends StatelessWidget {
  const ThemeSwitchTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final text = Theme.of(context).textTheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        return MergeSemantics(
          child: InkWell(
            onTap: () => ThemeController.instance.setDark(!dark),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: Row(
                children: [
                  MahadIcon(MahadIcons.moon, size: 21, color: c.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tungi rejim', style: text.titleMedium),
                        Text(dark ? 'Yoqilgan' : "O'chiq", style: text.bodySmall?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(value: dark, onChanged: ThemeController.instance.setDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
