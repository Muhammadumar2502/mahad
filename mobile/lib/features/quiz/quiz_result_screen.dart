import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'review.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.title,
    required this.solved,
    required this.total,
    required this.passPercent,
    required this.showPass,
    this.review,
  });

  final String title;
  final int solved;
  final int total;
  final int passPercent;
  final bool showPass;
  final ReviewData? review;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : solved * 100 / total;
    final passed = percent >= passPercent;
    final wrong = total - solved;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Natija'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(child: PercentRing(percent: percent, size: 150, stroke: 12, pass: passPercent)),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (showPass)
              Center(
                child: passed
                    ? Pill(
                        text: "O'tdingiz (≥$passPercent%)",
                        color: AppColors.primaryDark,
                        background: AppColors.primarySoft,
                        icon: Iconsax.cup,
                      )
                    : Pill(
                        text: "Keyingi bo'lim uchun kamida $passPercent% kerak",
                        color: AppColors.red,
                        background: AppColors.redSoft,
                        icon: Iconsax.info_circle,
                      ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                _stat("To'g'ri", '$solved', AppColors.primary),
                const SizedBox(width: 12),
                _stat("Noto'g'ri", '$wrong', AppColors.red),
                const SizedBox(width: 12),
                _stat('Jami', '$total', AppColors.blue),
              ],
            ),
            const SizedBox(height: 28),
            if (review != null) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReviewScreen(title: title, data: review!)),
                ),
                icon: const Icon(Iconsax.clipboard_tick),
                label: const Text("Javoblarni ko'rish"),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yopish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
