import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import '../quiz/quiz_launcher.dart';
import '../quiz/quiz_session.dart';

class SpecialTestsScreen extends StatefulWidget {
  const SpecialTestsScreen({super.key});

  @override
  State<SpecialTestsScreen> createState() => _SpecialTestsScreenState();
}

class _SpecialTestsScreenState extends State<SpecialTestsScreen> {
  final _view = GlobalKey<AsyncViewState<List<SpecialTest>>>();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Holatlar (boshlanmagan -> faol -> tugagan) real vaqtda yangilansin.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<List<SpecialTest>> _load() async {
    final list = await Repo.specialTests();
    final now = ApiClient.instance.serverNow;
    int rank(SpecialTest t) => switch (t.statusAt(now)) {
      SpecialStatus.active => 0,
      SpecialStatus.upcoming => 1,
      SpecialStatus.done => 2,
      SpecialStatus.expired => 3,
    };
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (b.start ?? DateTime(2000)).compareTo(a.start ?? DateTime(2000));
    });
    return list;
  }

  Future<void> _open(SpecialTest t) async {
    final now = ApiClient.instance.serverNow;
    switch (t.statusAt(now)) {
      case SpecialStatus.done:
        _info(t.name, "Siz bu testni topshirgansiz. Natijani \"Mening natijalarim\" bo'limida ko'rishingiz mumkin.");
        return;
      case SpecialStatus.upcoming:
        _info(t.name, 'Test ${t.start != null ? formatDate(t.start!) : ''} da boshlanadi.');
        return;
      case SpecialStatus.expired:
        _info(t.name, 'Test muddati tugagan.');
        return;
      case SpecialStatus.active:
        break;
    }
    final resume = QuizSession.load(QuizLauncher.specialKey(t.id)) != null;
    if (!resume) {
      final ok = await confirmDialog(
        context,
        title: t.name,
        message: [
          '${t.realQuestionCount} ta savol.',
          '${t.timing.label}.',
          if (t.forceNext) "Vaqt tugasa keyingi savolga avtomatik o'tiladi, orqaga qaytib bo'lmaydi.",
          'Test faqat bir marta topshiriladi.',
        ].join('\n'),
        confirm: 'Boshlash',
      );
      if (!ok || !mounted) return;
    }
    final done = await QuizLauncher.startSpecial(context, t);
    if (mounted) {
      done ? _view.currentState?.refresh() : setState(() {});
    }
  }

  void _info(String title, String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maxsus testlar')),
      body: AsyncView<List<SpecialTest>>(
        key: _view,
        load: _load,
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Hozircha maxsus test yo'q",
        emptySubtitle: 'Admin test biriktirganda shu yerda paydo bo\'ladi',
        emptyIcon: Iconsax.star,
        builder: (context, list, refresh) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _card(list[i]),
          ),
        ),
      ),
    );
  }

  Widget _card(SpecialTest t) {
    final st = t.statusAt(ApiClient.instance.serverNow);
    final pending = QuizSession.load(QuizLauncher.specialKey(t.id)) != null;
    final active = st == SpecialStatus.active;
    final done = st == SpecialStatus.done;
    final iconColor = done ? const Color(0xFF9C27B0) : (active ? AppColors.primary : AppColors.textMuted);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(t),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(done ? Iconsax.tick_circle_copy : Iconsax.document_text_copy, color: iconColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        if ((t.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(t.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(text: '${t.realQuestionCount} ta savol', color: AppColors.blue, background: AppColors.blueSoft, icon: Iconsax.message_question),
                  Pill(text: _timeLabel(t), color: AppColors.orange, background: AppColors.orangeSoft, icon: Iconsax.clock),
                  _statusPill(st),
                  if (pending && active)
                    const Pill(text: 'Davom ettirish', color: AppColors.orange, background: AppColors.orangeSoft, icon: Iconsax.play),
                ],
              ),
              if (t.start != null || t.end != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primarySoft : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? const Color(0xFFBFE3C9) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar, size: 18, color: active ? AppColors.primary : AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.start != null ? formatDate(t.start!) : '...'}  —  ${t.end != null ? formatDate(t.end!) : '...'}',
                          style: TextStyle(color: active ? AppColors.primaryDark : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(SpecialTest t) {
    final tm = t.timing;
    if (tm.hasPerQuestion) return 'Har savolga ${tm.perQuestionSeconds} s';
    if (tm.hasTotal) {
      final s = tm.totalSeconds!;
      final h = s ~/ 3600, m = (s % 3600) ~/ 60;
      return [if (h > 0) '$h soat', if (m > 0 || h == 0) '$m daqiqa'].join(' ');
    }
    return 'Vaqt cheklanmagan';
  }

  Widget _statusPill(SpecialStatus st) => switch (st) {
    SpecialStatus.active => const Pill(text: 'Faol', color: AppColors.primaryDark, background: AppColors.primarySoft, icon: Iconsax.tick_circle_copy),
    SpecialStatus.upcoming => const Pill(text: 'Boshlanmagan', color: AppColors.blue, background: AppColors.blueSoft, icon: Iconsax.timer_start),
    SpecialStatus.expired => const Pill(text: 'Faol emas', color: AppColors.textMuted, background: Color(0xFFF0F1F3), icon: Iconsax.timer_pause),
    SpecialStatus.done => const Pill(text: 'Yechilgan', color: Color(0xFF9C27B0), background: Color(0xFFF6E8F9), icon: Iconsax.task_square),
  };
}
