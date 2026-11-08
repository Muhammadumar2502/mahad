import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import 'quiz_session.dart';

class ReviewItem {
  ReviewItem({required this.question, required this.options, required this.correct, required this.mine});

  final String question;

  /// Ko'rinadigan harf -> matn.
  final Map<String, String> options;
  final String correct;
  final String mine;

  bool get isCorrect => mine.isNotEmpty && mine == correct;
  bool get isEmpty => mine.isEmpty;
}

/// Javoblarni ko'rib chiqish uchun ma'lumot — yangi sessiyadan yoki
/// serverdagi eski natijadan (eski formatlar ham) quriladi.
class ReviewData {
  ReviewData(this.items);

  final List<ReviewItem> items;

  int get correct => items.where((i) => i.isCorrect).length;

  /// [key] — savolId -> asl to'g'ri harf (maxsus testda serverdan keladi).
  factory ReviewData.fromSession(QuizSession s, {Map<int, String>? key}) => ReviewData([
    for (final q in s.questions)
      ReviewItem(
        question: q.text,
        options: {for (var i = 0; i < q.options.length; i++) answerLetters[i]: q.options[i].text},
        correct: q.displayLetter(key?[q.id] ?? q.correct),
        mine: s.answers[q.id] == null ? '' : q.displayLetter(s.answers[q.id]!),
      ),
  ]);

  /// Kitob/aralash test: answers = [{question, answer_A.., answer, my_answer}, ...]
  /// Maxsus test: answers = {questionId: "A"}, savollar alohida keladi.
  static ReviewData? fromRecord(ResultRecord r) {
    final a = r.answers;
    if (r.kind == ResultKind.special) {
      if (a is! Map || r.specialQuestions.isEmpty) return null;
      return ReviewData([
        for (final q in r.specialQuestions)
          ReviewItem(
            question: q.question,
            options: q.options,
            correct: q.answer,
            mine: asStr(a[q.id.toString()]).toUpperCase(),
          ),
      ]);
    }
    if (a is! List || a.isEmpty) return null;
    final items = <ReviewItem>[];
    for (final raw in a) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final opts = <String, String>{};
      for (final l in answerLetters) {
        final t = asStr(m['answer_$l']).trim();
        if (t.isNotEmpty) opts[l] = t;
      }
      items.add(ReviewItem(
        question: cleanQuestion(asStr(m['question'])),
        options: opts,
        correct: asStr(m['answer']).toUpperCase(),
        mine: asStr(m['my_answer']).toUpperCase(),
      ));
    }
    return items.isEmpty ? null : ReviewData(items);
  }
}

enum _Filter { all, wrong, correct }

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.title, required this.data});

  final String title;
  final ReviewData data;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.items;
    final indexed = [for (var i = 0; i < all.length; i++) (i, all[i])];
    final shown = indexed.where((e) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.wrong:
          return !e.$2.isCorrect;
        case _Filter.correct:
          return e.$2.isCorrect;
      }
    }).toList();
    final wrong = all.where((i) => !i.isCorrect).length;

    return BandPage(
      title: widget.title,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DoubleFrame(
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  for (final (f, label) in [
                    (_Filter.all, 'Hammasi (${all.length})'),
                    (_Filter.wrong, 'Xato ($wrong)'),
                    (_Filter.correct, "To'g'ri (${all.length - wrong})"),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _filter == f ? LinearGradient(colors: [context.mc.primaryStart, context.mc.primaryEnd]) : null,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(13.5, _filter == f ? FontWeight.w600 : FontWeight.w500, 18, _filter == f ? context.mc.priText : context.mc.ink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: shown.isEmpty
                  ? const EmptyView(key: ValueKey('empty'), title: "Bu bo'limda savol yo'q", icon: Iconsax.filter_remove)
                  : ListView.separated(
                      key: ValueKey(_filter),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => FadeSlideIn(index: i, child: _card(shown[i].$1 + 1, shown[i].$2)),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(int n, ReviewItem it) {
    final c = context.mc;
    return DoubleFrame(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$n-savol', style: AppTheme.body(13, FontWeight.w500, 18, c.muted)),
              const Spacer(),
              if (it.isEmpty)
                Pill.tone(context, text: 'Javobsiz', tone: PillTone.warn)
              else if (it.isCorrect)
                Pill.tone(context, text: "To'g'ri", tone: PillTone.ok)
              else
                Pill.tone(context, text: 'Xato', tone: PillTone.bad),
            ],
          ),
          const SizedBox(height: 8),
          Text(it.question, style: AppTheme.body(16, FontWeight.w600, 23, c.ink)),
          const SizedBox(height: 10),
          for (final e in it.options.entries) _option(e.key, e.value, it),
        ],
      ),
    );
  }

  Widget _option(String letter, String text, ReviewItem it) {
    final c = context.mc;
    final correct = letter == it.correct;
    final mineWrong = letter == it.mine && !correct;
    final color = correct ? c.okText : (mineWrong ? c.badText : c.ink);
    final fill = correct ? c.ok : (mineWrong ? c.bad : c.letterBg);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: ShapeDecoration(color: fill, shape: octagonBorder(24, side: BorderSide(color: correct || mineWrong ? fill : c.letterBd))),
            child: Center(
              child: correct
                  ? MahadIcon(MahadIcons.check, size: 14, color: c.okOn)
                  : mineWrong
                      ? MahadIcon(MahadIcons.close, size: 13, color: c.badOn)
                      : Text(letter, style: AppTheme.display(13, FontWeight.w700, 14, c.letterText)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: AppTheme.body(14.5, correct || mineWrong ? FontWeight.w600 : FontWeight.w400, 21, color)),
            ),
          ),
        ],
      ),
    );
  }
}
