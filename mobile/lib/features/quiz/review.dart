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

    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<_Filter>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: _Filter.all, label: Text('Hammasi (${all.length})')),
                ButtonSegment(value: _Filter.wrong, label: Text('Xato ($wrong)')),
                ButtonSegment(value: _Filter.correct, label: Text("To'g'ri (${all.length - wrong})")),
              ],
              selected: {_filter},
              onSelectionChanged: (v) => setState(() => _filter = v.first),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? const EmptyView(title: "Bu bo'limda savol yo'q", icon: Iconsax.filter_remove)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(shown[i].$1 + 1, shown[i].$2),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(int n, ReviewItem it) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('$n-savol', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (it.isEmpty)
                  const Pill(text: 'Javobsiz', color: AppColors.orange, background: AppColors.orangeSoft)
                else if (it.isCorrect)
                  const Pill(text: "To'g'ri", color: AppColors.primaryDark, background: AppColors.primarySoft)
                else
                  const Pill(text: 'Xato', color: AppColors.red, background: AppColors.redSoft),
              ],
            ),
            const SizedBox(height: 8),
            Text(it.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 10),
            for (final e in it.options.entries) _option(e.key, e.value, it),
          ],
        ),
      ),
    );
  }

  Widget _option(String letter, String text, ReviewItem it) {
    final correct = letter == it.correct;
    final mineWrong = letter == it.mine && !correct;
    final color = correct ? AppColors.primary : (mineWrong ? AppColors.red : AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: correct ? AppColors.primary : (mineWrong ? AppColors.red : AppColors.background),
              borderRadius: BorderRadius.circular(8),
            ),
            child: correct
                ? const Icon(Iconsax.tick_circle, size: 16, color: Colors.white)
                : mineWrong
                    ? const Icon(Iconsax.close_circle, size: 16, color: Colors.white)
                    : Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: TextStyle(
                  color: correct || mineWrong ? color : AppColors.text,
                  fontWeight: correct ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
