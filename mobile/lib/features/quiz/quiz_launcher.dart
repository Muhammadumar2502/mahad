import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/session.dart';
import '../../core/storage.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../widgets/common.dart';
import 'quiz_screen.dart';
import 'quiz_session.dart';

/// Testlarni boshlash / davom ettirish. Natija yuborilsa `true` qaytaradi.
class QuizLauncher {
  QuizLauncher._();

  static String bookKey(int testId) => 'book_$testId';
  static String specialKey(int id) => 'special_$id';
  static const randomKey = 'random';

  static Future<bool> open(BuildContext context, QuizSession s) async {
    final r = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => QuizScreen(session: s)),
    );
    return r == true;
  }

  static Future<QuizTiming> _groupTiming() async {
    try {
      return (await Session.group())?.timing ?? const QuizTiming();
    } catch (_) {
      return Session.cachedGroup?.timing ?? const QuizTiming();
    }
  }

  static void _err(Object e) => Session.toast(errorText(e), error: true);

  /// Kitob bo'limi testi. [restart] — eski sessiyani o'chirib yangidan.
  static Future<bool> startBook(
    BuildContext context, {
    required SectionDetail section,
    int passPercent = 60,
    bool restart = false,
  }) async {
    final testId = section.testId;
    if (testId == null) return false;
    final key = bookKey(testId);
    if (restart) await Storage.setQuiz(key, null);
    if (!context.mounted) return false;

    try {
      final session = await withLoading(context, () async {
        final items = await Repo.testItems(testId);
        if (items.isEmpty) throw ApiException("Bu bo'limda hali savollar yo'q");
        final saved = QuizSession.load(key);
        if (saved != null && saved.matches(items)) return saved;
        final timing = await _groupTiming();
        final s = QuizSession.create(
          key: key,
          kind: QuizKind.book,
          title: section.name,
          items: items,
          timing: timing,
          testId: testId,
          passPercent: passPercent,
        );
        await s.save();
        return s;
      });
      if (!context.mounted) return false;
      return await open(context, session);
    } catch (e) {
      _err(e);
      return false;
    }
  }

  static Future<bool> startRandom(
    BuildContext context, {
    required List<int> sectionIds,
    required int count,
  }) async {
    try {
      final session = await withLoading(context, () async {
        final items = await Repo.randomTest(sectionIds: sectionIds, count: count);
        if (items.isEmpty) throw ApiException("Tanlangan bo'limlarda savol topilmadi");
        final s = QuizSession.create(
          key: randomKey,
          kind: QuizKind.random,
          title: 'Aralash test',
          items: items,
          timing: await _groupTiming(),
        );
        await s.save();
        return s;
      });
      if (!context.mounted) return false;
      return await open(context, session);
    } catch (e) {
      _err(e);
      return false;
    }
  }

  static Future<bool> startSpecial(BuildContext context, SpecialTest test) async {
    final key = specialKey(test.id);
    try {
      final session = await withLoading(context, () async {
        // GET /special-test/:id — faolligini backend tekshiradi.
        final full = await Repo.specialTest(test.id);
        if (full.hasAttempted) throw ApiException('Siz bu testni allaqachon topshirgansiz');
        if (full.questions.isEmpty) throw ApiException("Bu testda savollar yo'q");
        final saved = QuizSession.load(key);
        if (saved != null && saved.matches(full.questions)) return saved;
        final s = QuizSession.create(
          key: key,
          kind: QuizKind.special,
          title: full.name,
          items: full.questions,
          timing: full.timing,
          specialId: full.id,
          activeUntil: full.end,
        );
        await s.save();
        return s;
      });
      if (!context.mounted) return false;
      return await open(context, session);
    } catch (e) {
      _err(e);
      return false;
    }
  }

  /// Bosh sahifadagi "Tugallanmagan test" uchun.
  static QuizSession? unfinished() {
    QuizSession? best;
    for (final j in _all()) {
      if (best == null || j.startedAt.isAfter(best.startedAt)) best = j;
    }
    return best;
  }

  static Iterable<QuizSession> _all() sync* {
    for (final raw in _rawAll()) {
      try {
        final s = QuizSession.fromJson(raw);
        if (s.questions.isNotEmpty && s.belongsToCurrentUser) yield s;
      } catch (_) {}
    }
  }

  static List<Map<String, dynamic>> _rawAll() => Storage.allQuizzes();
}
