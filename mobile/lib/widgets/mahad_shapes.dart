// Shapes and decorations of the G · Klassik Islomiy system: mihrab arch, octagon, double gold frame,
// girih pattern band. Pure presentation — no logic.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/mahad_colors.dart';

/// Pointed mihrab arch. Used for: question-number cells (38x44), section icons (38x46),
/// subject/book image plates (96x116), active NavigationBar indicator, Liderlar/Maxsus tiles.
class MihrabBorder extends OutlinedBorder {
  const MihrabBorder({super.side = BorderSide.none, this.shoulder = 0.36});

  /// Fraction of the height where the straight sides end and the arch begins.
  final double shoulder;

  Path _path(Rect r) {
    final w = r.width, h = r.height, x = r.left, y = r.top;
    final s = h * shoulder;
    return Path()
      ..moveTo(x, y + h)
      ..lineTo(x, y + s)
      ..cubicTo(x, y + s * 0.5, x + w * 0.25, y + s * 0.16, x + w / 2, y)
      ..cubicTo(x + w * 0.75, y + s * 0.16, x + w, y + s * 0.5, x + w, y + s)
      ..lineTo(x + w, y + h)
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  MihrabBorder copyWith({BorderSide? side, double? shoulder}) =>
      MihrabBorder(side: side ?? this.side, shoulder: shoulder ?? this.shoulder);

  @override
  ShapeBorder scale(double t) => MihrabBorder(side: side.scale(t), shoulder: shoulder);
}

/// Regular octagon ("8 qirra") of the given box size — answer letter badges, percent badges,
/// medallions, empty-state icons.
OutlinedBorder octagonBorder(double size, {BorderSide side = BorderSide.none}) =>
    BeveledRectangleBorder(borderRadius: BorderRadius.circular(size * 0.293), side: side);

/// Eight-pointed star outline (two squares) as a path, for medallions and the result ring frame.
Path octagramPath(Rect r) {
  final c = r.center;
  final rad = r.shortestSide / 2;
  final p = Path();
  for (var i = 0; i < 16; i++) {
    final a = -math.pi / 2 + i * math.pi / 8;
    final rr = i.isEven ? rad : rad * 0.765;
    final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  return p..close();
}

/// Card with the double gold frame: 1px outer line, 2px gap, 1px inner hairline.
class DoubleFrame extends StatelessWidget {
  const DoubleFrame({
    super.key,
    required this.child,
    this.radius = 12,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.shadow = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.frame),
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 16), spreadRadius: -20)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius - 2),
            border: Border.all(color: c.frameIn),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Repeating girih tile (40x40) — only on header bands, never behind questions.
class GirihPainter extends CustomPainter {
  GirihPainter({required this.color, this.tile = 40, this.strokeWidth = 1});

  final Color color;
  final double tile;
  final double strokeWidth;

  static Path tilePath(double s) {
    final k = s / 40;
    Offset o(double x, double y) => Offset(x * k, y * k);
    final pts = [
      o(20, 8), o(23.51, 11.51), o(28.49, 11.51), o(28.49, 16.49), o(32, 20), o(28.49, 23.51), o(28.49, 28.49), o(23.51, 28.49),
      o(20, 32), o(16.49, 28.49), o(11.51, 28.49), o(11.51, 23.51), o(8, 20), o(11.51, 16.49), o(11.51, 11.51), o(16.49, 11.51),
    ];
    final p = Path()..addPolygon(pts, true);
    p
      ..moveTo(20 * k, 0)
      ..lineTo(20 * k, 8 * k)
      ..moveTo(20 * k, 32 * k)
      ..lineTo(20 * k, 40 * k)
      ..moveTo(0, 20 * k)
      ..lineTo(8 * k, 20 * k)
      ..moveTo(32 * k, 20 * k)
      ..lineTo(40 * k, 20 * k);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final base = tilePath(tile);
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        canvas.drawPath(base.shift(Offset(x, y)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(GirihPainter old) => old.color != color || old.tile != tile || old.strokeWidth != strokeWidth;
}

/// Green header band with girih pattern, lamp glow and a 4px double gold bottom border.
/// Replaces the white AppBar visually; titles and actions stay the same widgets/callbacks.
class BandBackground extends StatelessWidget {
  const BandBackground({super.key, required this.height, this.child});

  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: c.bandGradient)),
          CustomPaint(painter: GirihPainter(color: c.bandPat.withValues(alpha: c.bandPatternOpacity))),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 0.9,
                colors: [c.bandOrn.withValues(alpha: 0.22), c.bandOrn.withValues(alpha: 0)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 1, color: c.bandLine),
                const SizedBox(height: 2),
                Container(height: 1, color: c.bandLine),
              ],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Small diamond ornament under titles: ——◆——
class Ornament extends StatelessWidget {
  const Ornament({super.key, this.color, this.width = 26, this.diamond = 6});

  final Color? color;
  final double width;
  final double diamond;

  @override
  Widget build(BuildContext context) {
    final col = color ?? context.mc.bandOrn;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: width, height: 1, color: col),
        const SizedBox(width: 6),
        Transform.rotate(angle: math.pi / 4, child: Container(width: diamond, height: diamond, color: col)),
        const SizedBox(width: 6),
        Container(width: width, height: 1, color: col),
      ],
    );
  }
}
