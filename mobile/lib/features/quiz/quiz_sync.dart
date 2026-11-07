import 'dart:async';

import '../../core/api_client.dart';
import '../../core/clock.dart';
import '../../core/session.dart';
import '../../core/storage.dart';
import 'quiz_session.dart';

/// Fondagi sinxronlash: tugagan (yoki vaqti o'tib ketgan), lekin serverga
/// yetib bormagan natijalarni avtomatik yuboradi.
///
/// Chaqiriladi: ilova ochilganda, fondan qaytganda, har daqiqada (kutayotgan
/// natija bo'lsa) va test ekrani yopilganda.
class QuizSync {
  QuizSync._();

  /// Hozir ekranda ochiq testlar — ularga tegilmaydi (ekran o'zi boshqaradi).
  static final Set<String> openKeys = {};

  /// Holat o'zgarganda (natija yuborildi / o'chirildi) xabar beradi — UI yangilanadi.
  static final StreamController<void> _changes = StreamController.broadcast();
  static Stream<void> get changes => _changes.stream;

  static bool _running = false;
  static Timer? _timer;

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (hasPending) run();
    });
    run();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static bool get hasPending => _sessions().any((s) => s.isFinished || s.isExpired);

  static Iterable<QuizSession> _sessions() sync* {
    for (final raw in Storage.allQuizzes()) {
      try {
        final s = QuizSession.fromJson(raw);
        if (s.questions.isNotEmpty && s.belongsToCurrentUser) yield s;
      } catch (_) {}
    }
  }

  static Future<void> run() async {
    if (_running || !Session.isLoggedIn) return;
    _running = true;
    var changed = false;
    try {
      for (final s in _sessions().toList()) {
        if (openKeys.contains(s.key)) continue;

        // Vaqti fonda tugab qolgan test — yakunlangan deb belgilaymiz.
        if (!s.isFinished && s.isExpired) {
          s.lockExpiredQuestions();
          s.finishedAt = AppClock.now();
          await s.save();
          changed = true;
        }
        if (!s.isFinished) continue;

        try {
          final r = await s.submit();
          await s.discard();
          changed = true;
          Session.toast('«${s.title}» natijasi yuborildi: ${r.solved}/${r.total}');
        } on ApiException catch (e) {
          if (e.isNetwork || (e.statusCode ?? 0) >= 500) break; // keyinroq qayta
          if (e.statusCode == 401) break; // global handler login'ga qaytaradi
          // Qayta yuborishdan foyda yo'q (test o'chirilgan / muddati o'tgan / topshirilgan).
          await s.discard();
          changed = true;
          Session.toast('«${s.title}» natijasi qabul qilinmadi: ${e.message}', error: true);
        } catch (_) {
          break;
        }
      }
    } finally {
      _running = false;
      if (changed) _changes.add(null);
    }
  }

  /// Sessiya qaysi turdagi test ekanini qisqa yozuv bilan.
  static String label(QuizSession s) => switch (s.kind) {
    QuizKind.book => "Bo'lim testi",
    QuizKind.random => 'Aralash test',
    QuizKind.special => 'Maxsus test',
  };

  static String? statusLine(QuizSession s) {
    if (s.isFinished || s.isExpired) return 'Natija yuborilmoqda...';
    final rem = s.totalRemaining;
    if (rem != null) return null; // UI taymer bilan ko'rsatadi
    return '${s.answeredCount}/${s.total} javob';
  }

}
