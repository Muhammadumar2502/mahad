// Shared presentation pieces of the G · Klassik Islomiy redesign: icon mapping, press / entrance
// motion, spinner, star medallion, buttons and the framed dialog shell. No business logic here.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/mahad_colors.dart';
import 'mahad_icons.dart';
import 'mahad_shapes.dart';

// ───────────────────────── Icons ─────────────────────────

/// Iconsax icon used in code → new SVG with the same meaning (DESIGN_SYSTEM §7).
/// Screens keep passing Iconsax constants; the drawing style changes only.
final Map<IconData, String> _iconMap = {
  Iconsax.home_2: MahadIcons.home,
  Iconsax.home_2_copy: MahadIcons.home,
  Iconsax.book_1: MahadIcons.manuscript,
  Iconsax.book: MahadIcons.bookSmall,
  Iconsax.heart: MahadIcons.heart,
  Iconsax.heart_copy: MahadIcons.heartFill,
  Iconsax.profile_circle: MahadIcons.profile,
  Iconsax.profile_circle_copy: MahadIcons.profile,
  Iconsax.search_normal_1: MahadIcons.search,
  Iconsax.close_circle: MahadIcons.close,
  Iconsax.arrow_left_2: MahadIcons.back,
  Iconsax.arrow_right_3: MahadIcons.chevronRight,
  Iconsax.arrow_down_1: MahadIcons.chevronDown,
  Iconsax.arrow_up_2: MahadIcons.chevronUp,
  Iconsax.timer_1: MahadIcons.hourglass,
  Iconsax.clock: MahadIcons.hourglass,
  Iconsax.timer: MahadIcons.hourglass,
  Iconsax.cup: MahadIcons.trophy,
  Iconsax.cup_copy: MahadIcons.trophy,
  Iconsax.lock_1: MahadIcons.lock,
  Iconsax.clipboard_tick: MahadIcons.clipboardTick,
  Iconsax.clipboard_tick_copy: MahadIcons.clipboardTick,
  Iconsax.clipboard_text: MahadIcons.clipboardText,
  Iconsax.shuffle: MahadIcons.shuffle,
  Iconsax.document_text: MahadIcons.document,
  Iconsax.document_text_copy: MahadIcons.document,
  Iconsax.play: MahadIcons.play,
  Iconsax.refresh: MahadIcons.refresh,
  Iconsax.wifi_square: MahadIcons.wifi,
  Iconsax.calendar: MahadIcons.calendar,
  Iconsax.calendar_1: MahadIcons.calendar,
  Iconsax.calendar_tick: MahadIcons.calendarTick,
  Iconsax.message_question: MahadIcons.question,
  Iconsax.people: MahadIcons.people,
  Iconsax.teacher: MahadIcons.people,
  Iconsax.mobile: MahadIcons.mobile,
  Iconsax.logout: MahadIcons.logout,
  Iconsax.trash: MahadIcons.trash,
  Iconsax.eye: MahadIcons.eye,
  Iconsax.eye_slash: MahadIcons.eyeSlash,
  Iconsax.import: MahadIcons.import_,
  Iconsax.import_1: MahadIcons.import_,
  Iconsax.arrow_right_1: MahadIcons.arrowRight,
  Iconsax.task: MahadIcons.task,
  Iconsax.filter_remove: MahadIcons.filterRemove,
  Iconsax.note_1: MahadIcons.note,
  Iconsax.search_status: MahadIcons.searchStatus,
  Iconsax.box: MahadIcons.searchStatus,
  Iconsax.tick_circle: MahadIcons.tickCircle,
  Iconsax.tick_circle_copy: MahadIcons.tickCircle,
  Iconsax.task_square: MahadIcons.taskSquare,
  Iconsax.timer_start: MahadIcons.timerStart,
  Iconsax.timer_pause: MahadIcons.timerPause,
  Iconsax.medal_star_copy: MahadIcons.medal,
  Iconsax.info_circle: MahadIcons.info,
  Iconsax.danger: MahadIcons.danger,
  Iconsax.star: MahadIcons.starOutline,
  Iconsax.star_1: MahadIcons.star,
};

String? mahadAssetFor(IconData icon) => _iconMap[icon];

/// Draws the redesigned SVG for an Iconsax constant (falls back to the glyph if unmapped).
class MIcon extends StatelessWidget {
  const MIcon(this.icon, {super.key, this.size = 22, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final asset = _iconMap[icon];
    if (asset == null) return Icon(icon, size: size, color: color);
    return MahadIcon(asset, size: size, color: color);
  }
}

// ───────────────────────── Motion ─────────────────────────

/// Gentle press feedback: the child shrinks slightly while a pointer is down. Uses a Listener,
/// so the child's own onTap / InkWell keeps working exactly as before.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.965, this.enabled = true});

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Fade + short rise when first built. [index] staggers list items.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 14, this.duration = const Duration(milliseconds: 420)});

  final Widget child;
  final int index;
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * math.min(widget.index, 8));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - _a.value)), child: child),
      ),
    );
  }
}

// ───────────────────────── Spinner ─────────────────────────

/// Ring arc + small octagram in the centre (DESIGN_SYSTEM › Loading).
class MahadSpinner extends StatefulWidget {
  const MahadSpinner({super.key, this.size = 40, this.color, this.track});

  final double size;
  final Color? color;
  final Color? track;

  @override
  State<MahadSpinner> createState() => _MahadSpinnerState();
}

class _MahadSpinnerState extends State<MahadSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _SpinnerPainter(
            t: _c.value,
            color: widget.color ?? mc.spinner,
            track: widget.track ?? mc.spinnerTrack,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.t, required this.color, required this.track});

  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = math.max(2.0, s * 0.075);
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(ring, 0, math.pi * 2, false, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    canvas.drawArc(ring, t * math.pi * 2 - math.pi / 2, math.pi * 0.62, false, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke);
    final c = rect.center;
    final star = Rect.fromCenter(center: c, width: s * 0.26, height: s * 0.26);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-t * math.pi);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawPath(octagramPath(star), Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => old.t != t || old.color != color || old.track != track;
}

// ───────────────────────── Medallions ─────────────────────────

enum MedallionTone { soft, bad, ok, gold, pur, info, grey, warn }

/// Eight-pointed star medallion with an icon (empty / error states, special tests, info marks).
class StarMedallion extends StatelessWidget {
  const StarMedallion({super.key, this.icon, this.child, this.size = 84, this.tone = MedallionTone.soft});

  final IconData? icon;
  final Widget? child;
  final double size;
  final MedallionTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final (Color fill, Color line, Color fg) = switch (tone) {
      MedallionTone.soft => (c.goldSoft, c.gold, c.icon),
      MedallionTone.bad => (c.badSoft, c.bad.withValues(alpha: 0.55), c.bad),
      MedallionTone.ok => (c.okSoft, c.ok.withValues(alpha: 0.55), c.ok),
      MedallionTone.gold => (c.goldSoft, c.gold, c.goldText),
      MedallionTone.pur => (c.purSoft, c.pur.withValues(alpha: 0.55), c.pur),
      MedallionTone.info => (c.infoSoft, c.info.withValues(alpha: 0.55), c.info),
      MedallionTone.grey => (c.greySoft, c.hair, c.greyText),
      MedallionTone.warn => (c.warnSoft, c.warn.withValues(alpha: 0.55), c.warn),
    };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(fill: fill, line: line),
        child: Center(child: child ?? (icon == null ? null : MIcon(icon!, size: size * 0.36, color: fg))),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.fill, required this.line});

  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(1);
    final p = octagramPath(r);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(p, Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    final inner = octagramPath(r.deflate(size.shortestSide * 0.11));
    canvas.drawPath(inner, Paint()
      ..color = line.withValues(alpha: line.a * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.line != line;
}

// ───────────────────────── Buttons ─────────────────────────

enum MahadButtonKind { primary, secondary, danger, dangerFilled }

/// Primary (Kun: emerald + gold hairline, Tun: gold gradient), secondary (outlined),
/// danger (outlined red) and danger-filled buttons with press motion and a loading state.
class MahadButton extends StatelessWidget {
  const MahadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = MahadButtonKind.primary,
    this.height = 52,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MahadButtonKind kind;
  final double height;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final enabled = onPressed != null && !loading;
    final disabled = onPressed == null && !loading;
    Gradient? gradient;
    Color? bg;
    Color fg;
    BorderSide side;
    switch (kind) {
      case MahadButtonKind.primary:
        gradient = disabled ? null : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.primaryStart, c.primaryEnd]);
        bg = disabled ? c.disBg : null;
        fg = disabled ? c.disText : c.priText;
        side = BorderSide(color: disabled ? Colors.transparent : c.gold.withValues(alpha: 0.55));
      case MahadButtonKind.secondary:
        bg = c.secBg;
        fg = disabled ? c.disText : c.secText;
        side = BorderSide(color: c.secBd);
      case MahadButtonKind.danger:
        bg = c.dangBg;
        fg = c.dangText;
        side = BorderSide(color: c.dangBd);
      case MahadButtonKind.dangerFilled:
        bg = c.dangFill;
        fg = c.dangOn;
        side = BorderSide.none;
    }
    final radius = BorderRadius.circular(8);
    final text = AppTheme.body(15, FontWeight.w600, 20, fg);
    Widget content = loading
        ? MahadSpinner(size: 22, color: fg, track: fg.withValues(alpha: 0.25))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[MIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
              Flexible(child: Text(label, style: text, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          );
    final button = DecoratedBox(
      decoration: BoxDecoration(color: bg, gradient: gradient, borderRadius: radius, border: Border.fromBorderSide(side)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            width: expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(loading), child: content)),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(button: true, enabled: enabled, child: PressScale(enabled: enabled, child: button));
  }
}

// ───────────────────────── Dialog shell ─────────────────────────

/// Double gold frame with 7px corner diamonds (dialogs, update card, question card).
class CornerFrame extends StatelessWidget {
  const CornerFrame({super.key, required this.child, this.radius = 14, this.padding = const EdgeInsets.all(20), this.shadow = true, this.color});

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool shadow;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: dark ? const Color(0xBF000000) : const Color(0x733C280A),
                      blurRadius: dark ? 34 : 30,
                      offset: Offset(0, dark ? 18 : 16),
                      spreadRadius: dark ? -22 : -20,
                    ),
                  ]
                : null,
          ),
          child: DoubleFrame(radius: radius, padding: padding, color: color, child: child),
        ),
        for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
          Positioned.fill(
            child: Align(
              alignment: a,
              child: FractionalTranslation(
                translation: Offset(a.x * 0.5 - 0, a.y * 0.5),
                child: Transform.rotate(angle: math.pi / 4, child: Container(width: 7, height: 7, color: c.gold)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shows [builder] as a dialog with a soft scale + fade entrance on the themed scrim.
Future<T?> showMahadDialog<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true, bool useRootNavigator = true}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.mc.scrim,
    useRootNavigator: useRootNavigator,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (_, anim, _, child) {
      final a = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(a), child: child),
      );
    },
  );
}
