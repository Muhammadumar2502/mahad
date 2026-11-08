import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final c = context.mc;
    final percent = total == 0 ? 0.0 : solved * 100 / total;
    final passed = percent >= passPercent;
    final wrong = total - solved;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.pageFlat,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: c.pageGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BandBackground(
                  height: 176,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 46),
                    child: Column(
                      children: [
                        Text('Natija', style: AppTheme.display(36, FontWeight.w600, 40, c.bandText).copyWith(letterSpacing: 0.7)),
                        const SizedBox(height: 4),
                        const Ornament(),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 96,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          children: [
                            Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.85, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                                child: PercentRing(percent: percent, size: 150, stroke: 12, pass: passPercent),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeSlideIn(
                              index: 2,
                              child: Text(title, textAlign: TextAlign.center, style: AppTheme.display(27, FontWeight.w700, 31, c.ink)),
                            ),
                            const SizedBox(height: 8),
                            if (showPass)
                              FadeSlideIn(
                                index: 3,
                                child: Center(
                                  child: passed
                                      ? Pill.tone(context, text: "O'tdingiz (≥$passPercent%)", tone: PillTone.ok, icon: Iconsax.cup)
                                      : Pill.tone(context, text: "Keyingi bo'lim uchun kamida $passPercent% kerak", tone: PillTone.bad, icon: Iconsax.info_circle),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Center(child: Ornament(color: c.gold, width: 36)),
                            const SizedBox(height: 14),
                            FadeSlideIn(
                              index: 4,
                              child: DoubleFrame(
                                padding: EdgeInsets.zero,
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      _stat(context, "To'g'ri", '$solved', c.okText),
                                      VerticalDivider(width: 1, color: c.hair),
                                      _stat(context, "Noto'g'ri", '$wrong', c.badText),
                                      VerticalDivider(width: 1, color: c.hair),
                                      _stat(context, 'Jami', '$total', c.ink),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        child: Column(
                          children: [
                            if (review != null) ...[
                              MahadButton(
                                kind: MahadButtonKind.secondary,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ReviewScreen(title: title, data: review!)),
                                ),
                                icon: Iconsax.clipboard_tick,
                                label: "Javoblarni ko'rish",
                              ),
                              const SizedBox(height: 12),
                            ],
                            MahadButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              label: 'Yopish',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    final c = context.mc;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: AppTheme.display(34, FontWeight.w700, 38, color)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: AppTheme.body(11, FontWeight.w700, 15, c.muted).copyWith(letterSpacing: 1.8)),
          ],
        ),
      ),
    );
  }
}
