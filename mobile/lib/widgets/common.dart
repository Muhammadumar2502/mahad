import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../core/env.dart';
import '../core/theme.dart';
import 'mahad_icons.dart';
import 'mahad_shapes.dart';
import 'mahad_ui.dart';

export 'mahad_ui.dart' show MIcon, PressScale, FadeSlideIn, MahadSpinner, StarMedallion, MedallionTone, MahadButton, MahadButtonKind, CornerFrame, showMahadDialog;
export 'mahad_shapes.dart';
export 'mahad_icons.dart';
export 'band_page.dart';

/// Future'ni yuklaydi va loading / xato (qayta urinish) / bo'sh / ma'lumot
/// holatlarini bir xil ko'rsatadi. Pastga tortib yangilash ham bor.
///
/// Real vaqt:
///  * [refreshInterval] berilsa — ekran ko'rinib turganda fonda jim yangilanadi;
///  * ilova fondan qaytganda avtomatik yangilanadi;
///  * internet yo'qligidan yuklanmagan bo'lsa — o'zi qayta urinadi.
/// Fondagi yangilanish xatosi foydalanuvchini bezovta qilmaydi (eski ma'lumot qoladi).
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = "Ma'lumot yo'q",
    this.emptySubtitle,
    this.emptyIcon = Iconsax.box,
    this.refreshInterval,
    this.refreshOnResume = true,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;
  final Duration? refreshInterval;
  final bool refreshOnResume;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> with WidgetsBindingObserver {
  T? _data;
  Object? _error;
  bool _loading = true;
  bool _busy = false;
  int _req = 0;
  Timer? _timer;
  Timer? _retry;
  DateTime _lastLoad = DateTime.fromMillisecondsSinceEpoch(0);
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
    final every = widget.refreshInterval;
    if (every != null) {
      _timer = Timer.periodic(every, (_) {
        if (_foreground && _visible) _load(silent: true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _retry?.cancel();
    super.dispose();
  }

  bool get _visible => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && widget.refreshOnResume && _visible &&
        DateTime.now().difference(_lastLoad) > const Duration(seconds: 10)) {
      _load(silent: true);
    }
  }

  /// Foydalanuvchi so'ragan yangilash (pull-to-refresh, "Qayta urinish").
  Future<void> refresh() => _load(silent: false);

  Future<void> _load({required bool silent}) async {
    if (_busy && silent) return;
    _busy = true;
    _retry?.cancel();
    final id = ++_req;
    if (mounted && !silent) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }
    try {
      final d = await widget.load();
      if (!mounted || id != _req) return;
      _lastLoad = DateTime.now();
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _req) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (_data != null && !silent) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(errorText(e)), backgroundColor: context.mc.toastBadBg),
        );
      }
      // Internet yo'q / server javob bermadi — biroz kutib o'zi qayta urinadi.
      if (e is ApiException && e.isNetwork) {
        _retry = Timer(const Duration(seconds: 8), () {
          if (_foreground && _visible) _load(silent: true);
        });
      }
    } finally {
      if (id == _req) _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) return const LoadingView();
    if (_data == null) {
      return ErrorView(message: errorText(_error), onRetry: refresh);
    }
    final data = _data as T;
    if (widget.isEmpty?.call(data) ?? false) {
      return RefreshIndicator(
        color: context.mc.spinner,
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: EmptyView(
                title: widget.emptyTitle,
                subtitle: widget.emptySubtitle,
                icon: widget.emptyIcon,
              ),
            ),
          ],
        ),
      );
    }
    return widget.builder(context, data, refresh);
  }
}

String errorText(Object? e) {
  if (e is ApiException) return e.message;
  if (e == null) return 'Xatolik yuz berdi';
  return "Kutilmagan xatolik yuz berdi";
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.text = "Yuklanmoqda..."});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MahadSpinner(size: 44),
            const SizedBox(height: 16),
            Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mc.muted)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StarMedallion(icon: Iconsax.wifi_square, tone: MedallionTone.bad),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15.5, height: 1.45),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: 200,
                  child: MahadButton(label: 'Qayta urinish', icon: Iconsax.refresh, onPressed: onRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.subtitle, this.icon = Iconsax.box});

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final heart = icon == Iconsax.heart || icon == Iconsax.heart_copy;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarMedallion(icon: icon, tone: heart ? MedallionTone.bad : MedallionTone.soft),
              const SizedBox(height: 18),
              Text(title, textAlign: TextAlign.center, style: AppTheme.display(24, FontWeight.w700, 28, context.mc.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: context.mc.muted, fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Server rasmi; yuklanmasa chiroyli zaxira ko'rinish.
class NetImage extends StatelessWidget {
  const NetImage({super.key, required this.path, this.fit = BoxFit.cover, this.fallbackIcon = Iconsax.book_1});

  final String? path;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final url = Env.imageUrl(path);
    final fallback = Container(
      color: c.goldSoft,
      alignment: Alignment.center,
      child: MIcon(fallbackIcon, color: c.icon, size: 40),
    );
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => Container(color: c.card2),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// Mihrab-arch image plate (subject: dark green plate, book: parchment `imgPlate`).
class ArchPlate extends StatelessWidget {
  const ArchPlate({super.key, required this.child, this.width = 96, this.height = 116, this.color, this.padding = 4});

  final Widget child;
  final double width;
  final double height;
  final Color? color;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(color: color ?? c.imgPlate, shape: MihrabBorder(side: BorderSide(color: c.gold.withValues(alpha: 0.85), width: 1.2))),
      padding: EdgeInsets.all(padding),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: const MihrabBorder()),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(shape: MihrabBorder(side: BorderSide(color: c.gold.withValues(alpha: 0.35)))),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

/// Dashed hairline separator between rows inside one DoubleFrame.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final col = context.mc.hair;
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: LayoutBuilder(
        builder: (_, box) {
          final n = (box.maxWidth / 7).floor();
          return Row(children: [for (var i = 0; i < n; i++) Container(width: 4, height: 1, margin: const EdgeInsets.only(right: 3), color: col)]);
        },
      ),
    );
  }
}

/// 50px search field: gold search icon, 32px clear button only while there is text.
class MahadSearchField extends StatelessWidget {
  const MahadSearchField({super.key, required this.controller, required this.hint, required this.onChanged, this.onClear});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  /// Null = no clear button (keeps screens that never had one unchanged).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.inputBd));
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -12)],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTheme.body(15, FontWeight.w400, 20, c.ink),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: c.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: border,
            border: border,
            prefixIcon: Padding(padding: const EdgeInsets.all(14), child: MIcon(Iconsax.search_normal_1, size: 20, color: c.icon)),
            suffixIcon: controller.text.isEmpty || onClear == null
                ? null
                : Padding(
                    padding: const EdgeInsets.all(9),
                    child: PressScale(
                      child: Material(
                        color: c.card2,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onClear,
                          child: SizedBox(width: 32, height: 32, child: Center(child: MahadIcon(MahadIcons.close, size: 16, color: c.muted))),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class SvgIcon extends StatelessWidget {
  const SvgIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

enum PillTone { ok, bad, warn, info, pur, grey, gold }

class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.color, required this.background, this.icon});

  /// Tone pill from the design system (soft background + strong text).
  factory Pill.tone(BuildContext context, {Key? key, required String text, required PillTone tone, IconData? icon}) {
    final c = context.mc;
    final (fg, bg) = switch (tone) {
      PillTone.ok => (c.okText, c.okSoft),
      PillTone.bad => (c.badText, c.badSoft),
      PillTone.warn => (c.warnText, c.warnSoft),
      PillTone.info => (c.infoText, c.infoSoft),
      PillTone.pur => (c.purText, c.purSoft),
      PillTone.grey => (c.greyText, c.greySoft),
      PillTone.gold => (c.goldSoftText, c.goldSoft),
    };
    return Pill(key: key, text: text, color: fg, background: bg, icon: icon);
  }

  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[MIcon(icon!, size: 13, color: color), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(12, FontWeight.w600, 16, color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Octagon-bevel percent badge (soft in lists, [solid] for rating / results).
class PercentBadge extends StatelessWidget {
  const PercentBadge({super.key, required this.text, required this.tone, this.solid = false});

  final String text;
  final PercentTone tone;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final (fg, bg) = switch ((tone, solid)) {
      (PercentTone.ok, false) => (c.okText, c.okSoft),
      (PercentTone.warn, false) => (c.warnText, c.warnSoft),
      (PercentTone.bad, false) => (c.badText, c.badSoft),
      (PercentTone.ok, true) => (c.okSolidOn, c.okSolid),
      (PercentTone.warn, true) => (c.warnSolidOn, c.warnSolid),
      (PercentTone.bad, true) => (c.badSolidOn, c.badSolid),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: ShapeDecoration(color: bg, shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(6))),
      child: Text(text, style: AppTheme.body(12.5, FontWeight.w700, 16, fg)),
    );
  }
}

enum PercentTone { ok, warn, bad }

/// Foiz bo'yicha ton (rang qoidasi o'zgarmagan).
PercentTone percentTone(double p, {int pass = 60}) {
  if (p >= pass) return PercentTone.ok;
  if (p >= pass / 2) return PercentTone.warn;
  return PercentTone.bad;
}

MahadColors get _mc => ThemeController.instance.isDark ? MahadColors.tun : MahadColors.kun;

/// Foiz bo'yicha rang.
Color percentColor(double p, {int pass = 60}) => switch (percentTone(p, pass: pass)) {
  PercentTone.ok => _mc.ok,
  PercentTone.warn => _mc.warn,
  PercentTone.bad => _mc.bad,
};

String formatPercent(double p) =>
    p == p.roundToDouble() ? '${p.toInt()}%' : '${p.toStringAsFixed(1)}%';

/// Result medallion: eight-pointed star with an animated gradient ring and the percent.
/// [size] is the ring area; the star frame is 1.4× larger (150 → 210).
class PercentRing extends StatelessWidget {
  const PercentRing({super.key, required this.percent, this.size = 52, this.pass = 60, this.stroke = 5});

  final double percent;
  final double size;
  final int pass;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final tone = percentTone(percent, pass: pass);
    final (a, b, fg) = switch (tone) {
      PercentTone.ok => (c.ringOkStart, c.ringOkEnd, c.okText),
      PercentTone.warn => (c.ringWarnStart, c.ringWarnEnd, c.warnText),
      PercentTone.bad => (c.ringBadStart, c.ringBadEnd, c.badText),
    };
    final box = size * 1.4;
    final value = (percent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: box,
      height: box,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => CustomPaint(
          painter: _MedallionPainter(value: v, fill: c.card, line: c.gold, track: c.track, start: a, end: b, ringScale: box / 210),
          child: Center(
            child: Text(
              '${(v * 100).round()}%',
              style: AppTheme.display(44 * box / 210, FontWeight.w700, 48 * box / 210, fg),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.value, required this.fill, required this.line, required this.track, required this.start, required this.end, required this.ringScale});

  final double value;
  final Color fill, line, track, start, end;
  final double ringScale;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(1.5);
    final star = octagramPath(r);
    canvas.drawShadow(star, Colors.black.withValues(alpha: 0.35), 10, false);
    canvas.drawPath(star, Paint()..color = fill);
    canvas.drawPath(star, Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    canvas.drawPath(octagramPath(r.deflate(size.shortestSide * 0.06)), Paint()
      ..color = line.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    final ringR = 64 * ringScale;
    final sw = 10 * ringScale;
    final rr = Rect.fromCircle(center: r.center, radius: ringR);
    canvas.drawArc(rr, 0, math.pi * 2, false, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw);
    if (value > 0) {
      canvas.drawArc(rr, -math.pi / 2, math.pi * 2 * value, false, Paint()
        ..shader = SweepGradient(startAngle: -math.pi / 2, endAngle: math.pi * 1.5, colors: [start, end], transform: const GradientRotation(-math.pi / 2)).createShader(rr)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = sw);
    }
  }

  @override
  bool shouldRepaint(_MedallionPainter old) => old.value != value || old.fill != fill || old.start != start;
}

/// Two-button confirmation in the framed dialog (texts and return value unchanged).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Ha',
  String cancel = 'Bekor qilish',
  bool danger = false,
}) async {
  final r = await showMahadDialog<bool>(
    context,
    useRootNavigator: false,
    builder: (ctx) => MahadDialog(
      title: title,
      message: message,
      actions: [
        MahadButton(label: cancel, kind: MahadButtonKind.secondary, height: 44, onPressed: () => Navigator.pop(ctx, false)),
        MahadButton(
          label: confirm,
          kind: danger ? MahadButtonKind.dangerFilled : MahadButtonKind.primary,
          height: 44,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// One-button information dialog ("Tushunarli" / "Yopish"), optional octagon icon.
Future<void> infoDialog(BuildContext context, {required String title, required String message, String button = 'Tushunarli', IconData? icon}) {
  return showMahadDialog<void>(
    context,
    useRootNavigator: false,
    builder: (ctx) => MahadDialog(
      title: title,
      message: message,
      icon: icon,
      actions: [MahadButton(label: button, height: 44, onPressed: () => Navigator.pop(ctx))],
    ),
  );
}

/// Framed dialog body: optional 60px octagon icon (centred layout), Cormorant title, message,
/// equal-width buttons.
class MahadDialog extends StatelessWidget {
  const MahadDialog({super.key, required this.title, required this.message, required this.actions, this.icon, this.content});

  final String title;
  final String message;
  final List<Widget> actions;
  final IconData? icon;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final centred = icon != null;
    final align = centred ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centred ? TextAlign.center : TextAlign.start;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            type: MaterialType.transparency,
            child: CornerFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: align,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 60,
                      height: 60,
                      decoration: ShapeDecoration(color: c.card2, shape: octagonBorder(60, side: BorderSide(color: c.frame))),
                      child: Center(child: MIcon(icon!, size: 26, color: c.icon)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(title, textAlign: textAlign, style: AppTheme.display(25, FontWeight.w700, 30, c.ink)),
                  const SizedBox(height: 10),
                  Text(message, textAlign: textAlign, style: AppTheme.body(14.5, FontWeight.w400, 22, c.ink)),
                  if (content != null) ...[const SizedBox(height: 12), content!],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloklovchi yuklanish oynasi. `await` qilinadigan amal tugaguncha turadi.
Future<T> withLoading<T>(BuildContext context, Future<T> Function() task) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showMahadDialog<void>(
    context,
    dismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: SizedBox(
          width: 96,
          height: 96,
          child: CornerFrame(padding: EdgeInsets.zero, child: Center(child: MahadSpinner(size: 40))),
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    if (nav.canPop()) nav.pop();
  }
}

String formatDate(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
}

String formatDuration(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
