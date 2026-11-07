import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api_client.dart';
import '../core/env.dart';
import '../core/theme.dart';

/// Future'ni yuklaydi va loading / xato (qayta urinish) / bo'sh / ma'lumot
/// holatlarini bir xil ko'rsatadi. Pastga tortib yangilash ham bor.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = "Ma'lumot yo'q",
    this.emptySubtitle,
    this.emptyIcon = Iconsax.box,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() refresh) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptySubtitle;
  final IconData emptyIcon;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  int _req = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final id = ++_req;
    if (mounted) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }
    try {
      final d = await widget.load();
      if (!mounted || id != _req) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _req) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (_data != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(errorText(e)), backgroundColor: AppColors.red),
        );
      }
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
        color: AppColors.primary,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: AppColors.textMuted)),
        ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.redSoft, shape: BoxShape.circle),
              child: const Icon(Iconsax.wifi_square, color: AppColors.red, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('Qayta urinish'),
                ),
              ),
            ],
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            ],
          ],
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
    final url = Env.imageUrl(path);
    final fallback = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: AppColors.primary, size: 40),
    );
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, _) => Container(color: const Color(0xFFF0F1F3)),
      errorWidget: (_, _, _) => fallback,
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

class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.color, required this.background, this.icon});

  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Foiz bo'yicha rang.
Color percentColor(double p, {int pass = 60}) {
  if (p >= pass) return AppColors.primary;
  if (p >= pass / 2) return AppColors.orange;
  return AppColors.red;
}

String formatPercent(double p) =>
    p == p.roundToDouble() ? '${p.toInt()}%' : '${p.toStringAsFixed(1)}%';

class PercentRing extends StatelessWidget {
  const PercentRing({super.key, required this.percent, this.size = 52, this.pass = 60, this.stroke = 5});

  final double percent;
  final double size;
  final int pass;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final c = percentColor(percent, pass: pass);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (percent / 100).clamp(0, 1),
              strokeWidth: stroke,
              backgroundColor: AppColors.border,
              color: c,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: TextStyle(fontSize: size * 0.24, fontWeight: FontWeight.w700, color: c),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Ha',
  String cancel = 'Bekor qilish',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: TextStyle(color: danger ? AppColors.red : AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Bloklovchi yuklanish oynasi. `await` qilinadigan amal tugaguncha turadi.
Future<T> withLoading<T>(BuildContext context, Future<T> Function() task) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
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
