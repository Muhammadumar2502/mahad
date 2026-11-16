import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/services.dart';

import '../../core/device.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'splash_screen.dart';

/// Ilova versiyasi backend talab qilganidan past bo'lsa ko'rsatiladi.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, this.requiredVersion, this.message});

  final String? requiredVersion;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: c.bandEnd,
          body: BandBackground(
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: FadeSlideIn(
                    child: CornerFrame(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: ShapeDecoration(
                              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.bandStart, c.bandEnd]),
                              shape: octagonBorder(84, side: BorderSide(color: c.gold.withValues(alpha: 0.7))),
                            ),
                            child: Center(child: MIcon(Iconsax.import_1, color: c.bandText, size: 34)),
                          ),
                          const SizedBox(height: 18),
                          Text('Yangilanish mavjud!', textAlign: TextAlign.center, style: AppTheme.display(28, FontWeight.w700, 32, c.ink)),
                          const SizedBox(height: 10),
                          Text(
                            message ?? 'Ilovaning yangi versiyasi mavjud. Davom etish uchun yangilang.',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(14.5, FontWeight.w400, 22, c.muted),
                          ),
                          const SizedBox(height: 18),
                          DoubleFrame(
                            color: c.card2,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Row(
                              children: [
                                Expanded(child: _ver(context, 'Joriy versiya', DeviceData.appVersion, c.ink)),
                                MahadIcon(MahadIcons.arrowRight, size: 20, color: c.icon),
                                Expanded(child: _ver(context, 'Yangi versiya', requiredVersion ?? '—', c.okText)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          MahadButton(
                            onPressed: () => SystemNavigator.pop(),
                            icon: Iconsax.import,
                            label: 'Ilovani yopish',
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const SplashScreen()),
                              (_) => false,
                            ),
                            child: const Text('Qayta tekshirish'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ver(BuildContext context, String label, String value, Color color) {
    final c = context.mc;
    return Column(
      children: [
        Text(label, style: AppTheme.body(12.5, FontWeight.w400, 17, c.muted)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.display(24, FontWeight.w700, 28, color)),
      ],
    );
  }
}
