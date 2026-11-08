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
  SpecialStatus? _filter; // null — hammasi
  final _view = GlobalKey<AsyncViewState<List<SpecialTest>>>();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Holatlar (boshlanmagan -> faol -> tugagan) real vaqtda yangilansin.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
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
    infoDialog(context, title: title, message: msg, button: 'Yopish');
  }

  @override
  Widget build(BuildContext context) {
    return BandPage(
      title: 'Maxsus testlar',
      body: AsyncView<List<SpecialTest>>(
        key: _view,
        load: _load,
        refreshInterval: const Duration(seconds: 60),
        isEmpty: (l) => l.isEmpty,
        emptyTitle: "Hozircha maxsus test yo'q",
        emptySubtitle: 'Admin test biriktirganda shu yerda paydo bo\'ladi',
        emptyIcon: Iconsax.star,
        builder: (context, all, refresh) {
          final now = ApiClient.instance.serverNow;
          int count(SpecialStatus st) => all.where((t) => t.statusAt(now) == st).length;
          final list = _filter == null ? all : all.where((t) => t.statusAt(now) == _filter).toList();
          Widget chip(String label, SpecialStatus? v) =>
              MahadChip(label: label, selected: _filter == v, onTap: () => setState(() => _filter = v));

          return RefreshIndicator(
            color: context.mc.spinner,
            onRefresh: refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      children: [
                        chip('Hammasi (${all.length})', null),
                        chip('Faol (${count(SpecialStatus.active)})', SpecialStatus.active),
                        chip('Boshlanmagan (${count(SpecialStatus.upcoming)})', SpecialStatus.upcoming),
                        chip('Yechilgan (${count(SpecialStatus.done)})', SpecialStatus.done),
                        chip('Tugagan (${count(SpecialStatus.expired)})', SpecialStatus.expired),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyView(title: "Bu bo'limda test yo'q", icon: Iconsax.filter_remove),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _card(list[i])),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(SpecialTest t) {
    final c = context.mc;
    final st = t.statusAt(ApiClient.instance.serverNow);
    final pending = QuizSession.load(QuizLauncher.specialKey(t.id)) != null;
    final active = st == SpecialStatus.active;
    final done = st == SpecialStatus.done;
    final tone = done ? MedallionTone.pur : (active ? MedallionTone.ok : MedallionTone.grey);

    return PressScale(
      scale: 0.98,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(t),
          child: DoubleFrame(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StarMedallion(size: 54, tone: tone, icon: done ? Iconsax.task_square : Iconsax.document_text_copy),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: AppTheme.display(23, FontWeight.w700, 27, c.ink)),
                          if ((t.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(t.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.body(13, FontWeight.w400, 18, c.muted)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill.tone(context, text: '${t.realQuestionCount} ta savol', tone: PillTone.info, icon: Iconsax.message_question),
                    Pill.tone(context, text: _timeLabel(t), tone: PillTone.warn, icon: Iconsax.clock),
                    _statusPill(st),
                    if (pending && active) Pill.tone(context, text: 'Davom ettirish', tone: PillTone.warn, icon: Iconsax.play),
                  ],
                ),
                if (t.start != null || t.end != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? c.okTint : c.card2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? c.ok.withValues(alpha: 0.35) : c.hair),
                    ),
                    child: Row(
                      children: [
                        MIcon(Iconsax.calendar, size: 17, color: active ? c.ok : c.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${t.start != null ? formatDate(t.start!) : '...'}  —  ${t.end != null ? formatDate(t.end!) : '...'}',
                            style: AppTheme.body(13, FontWeight.w500, 18, active ? c.okText : c.muted),
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
    SpecialStatus.active => Pill.tone(context, text: 'Faol', tone: PillTone.ok, icon: Iconsax.tick_circle_copy),
    SpecialStatus.upcoming => Pill.tone(context, text: 'Boshlanmagan', tone: PillTone.info, icon: Iconsax.timer_start),
    SpecialStatus.expired => Pill.tone(context, text: 'Faol emas', tone: PillTone.grey, icon: Iconsax.timer_pause),
    SpecialStatus.done => Pill.tone(context, text: 'Yechilgan', tone: PillTone.pur, icon: Iconsax.task_square),
  };
}
