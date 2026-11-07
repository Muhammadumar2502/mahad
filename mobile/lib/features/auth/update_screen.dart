import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/services.dart';

import '../../core/device.dart';
import '../../core/theme.dart';
import 'splash_screen.dart';

/// Ilova versiyasi backend talab qilganidan past bo'lsa ko'rsatiladi.
class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, this.requiredVersion, this.message});

  final String? requiredVersion;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF245B36), Color(0xFF1B3F28)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF43A85E), Color(0xFF6CC27E)]),
                        ),
                        child: const Icon(Iconsax.import_1, color: Colors.white, size: 46),
                      ),
                      const SizedBox(height: 20),
                      const Text('Yangilanish mavjud!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                        message ?? 'Ilovaning yangi versiyasi mavjud. Davom etish uchun yangilang.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _ver('Joriy versiya', DeviceData.appVersion, AppColors.text)),
                            const Icon(Iconsax.arrow_right_1, color: AppColors.primary),
                            Expanded(child: _ver('Yangi versiya', requiredVersion ?? '—', AppColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: () => SystemNavigator.pop(),
                        icon: const Icon(Iconsax.import),
                        label: const Text('Ilovani yopish'),
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
    );
  }

  Widget _ver(String label, String value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}
