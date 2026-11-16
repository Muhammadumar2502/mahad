// Pushed-screen scaffold of the redesign: 138px girih band with a round back button (44px at
// top 44), centred Cormorant title + ornament (title at 74) and optional round action buttons.
// Replaces the white AppBar visually; back = Navigator.maybePop, exactly like AppBar's default.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/mahad_colors.dart';
import 'mahad_icons.dart';
import 'mahad_shapes.dart';
import 'mahad_ui.dart';

class BandPage extends StatelessWidget {
  const BandPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.uppercase = false,
    this.bandHeight = 138,
    this.showBack = true,
    this.bottom,
    this.overlap = 0,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool uppercase;
  final double bandHeight;
  final bool showBack;

  /// Optional bottom area (e.g. fixed buttons) placed above the system inset.
  final Widget? bottom;

  /// How far the body starts above the band edge (cards straddling the gold line).
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = AppTheme.display(28, FontWeight.w700, 32, c.bandText).copyWith(letterSpacing: uppercase ? 1.7 : 0.3);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: c.pageFlat,
        bottomNavigationBar: bottom,
        body: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: c.pageGradient)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BandBackground(
                height: bandHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 74,
                      left: 72,
                      right: 72,
                      child: Column(
                        children: [
                          Text(
                            uppercase ? title.toUpperCase() : title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style,
                          ),
                          const SizedBox(height: 3),
                          const Ornament(),
                        ],
                      ),
                    ),
                    if (showBack)
                      Positioned(
                        top: 44,
                        left: 16,
                        child: BandIconButton(
                          asset: MahadIcons.back,
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                    if (actions.isNotEmpty)
                      Positioned(
                        top: 44,
                        right: 16,
                        child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(top: bandHeight - overlap, child: body),
          ],
        ),
      ),
    );
  }
}

/// 44px round button on the band: 1px `bandBtnBd` border, `bandBtnBg` fill, icon in `bandText`.
class BandIconButton extends StatelessWidget {
  const BandIconButton({super.key, this.asset, this.icon, required this.onPressed, this.tooltip, this.size = 44});

  final String? asset;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final child = asset != null ? MahadIcon(asset!, size: 20, color: c.bandText) : MIcon(icon!, size: 20, color: c.bandText);
    Widget b = PressScale(
      child: Material(
        color: c.bandBtnBg,
        shape: CircleBorder(side: BorderSide(color: c.bandBtnBd)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: Center(child: child)),
        ),
      ),
    );
    if (tooltip != null) b = Tooltip(message: tooltip!, child: b);
    return b;
  }
}
