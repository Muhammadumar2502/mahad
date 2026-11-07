import 'dart:math';

import '../../core/clock.dart';
import '../../core/session.dart';
import '../../core/storage.dart';
import '../../data/models.dart';
import '../../data/repository.dart';

enum QuizKind { book, random, special }

class QuizOption {
  QuizOption(this.original, this.text);

  /// Backenddagi asl harf (A..D).
  final String original;
  final String text;

  Map<String, dynamic> toJson() => {'o': original, 't': text};

  factory QuizOption.fromJson(Map<String, dynamic> j) =>
      QuizOption(asStr(j['o']), asStr(j['t']));
}

class QuizQuestion {
  QuizQuestion({required this.id, required this.text, required this.options, required this.correct});

  final int id;
  final String text;

  /// Ko'rsatiladigan tartibda (aralashtirilgan). Ko'rinadigan harf = indeks bo'yicha A..D.
  final List<QuizOption> options;

  /// Asl to'g'ri harf.
  final String correct;

  String displayLetter(String original) {
    final i = options.indexWhere((o) => o.original == original);
    return i < 0 ? '' : answerLetters[i];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'correct': correct,
    'options': options.map((o) => o.toJson()).toList(),
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    id: asInt(j['id']) ?? 0,
    text: asStr(j['text']),
    correct: asStr(j['correct']),
    options: asMapList(j['options']).map(QuizOption.fromJson).toList(),
  );
}

/// Bitta test urinishining to'liq holati. Har o'zgarishda lokal saqlanadi —
/// ilova yopilsa ham davom ettirish mumkin, taymer esa to'xtamaydi.
class QuizSession {
  QuizSession({
    required this.key,
    required this.kind,
    required this.title,
    this.testId,
    this.specialId,
    this.passPercent = 60,
    required this.timing,
    required this.questions,
    required this.startedAt,
    this.deadline,
    this.hardDeadline,
    Map<int, String>? answers,
    Set<int>? locked,
    Map<int, int>? questionDeadlines,
    this.current = 0,
    this.finishedAt,
    this.ownerId,
  }) : answers = answers ?? {},
       locked = locked ?? {},
       questionDeadlines = questionDeadlines ?? {};

  final String key;
  final QuizKind kind;

  /// Qaysi o'quvchiniki (boshqa akkauntga natija yuborilmasligi uchun).
  final int? ownerId;

  bool get belongsToCurrentUser => ownerId == null || ownerId == Session.user?.id;
  final String title;
  final int? testId;
  final int? specialId;
  final int passPercent;
  final QuizTiming timing;
  final List<QuizQuestion> questions;
  final DateTime startedAt;

  /// Umumiy vaqt tugash payti (timing.totalSeconds bo'lsa).
  final DateTime? deadline;

  /// Qat'iy chegara — maxsus test faollik muddati tugashidan biroz oldin.
  /// Shu paytgacha natija albatta yuboriladi (aks holda server qabul qilmaydi).
  final DateTime? hardDeadline;

  /// Ikkalasidan eng yaqini.
  DateTime? get effectiveDeadline {
    if (deadline == null) return hardDeadline;
    if (hardDeadline == null) return deadline;
    return deadline!.isBefore(hardDeadline!) ? deadline : hardDeadline;
  }

  /// Vaqt tugaganmi (umumiy yoki qat'iy chegara)?
  bool get isExpired {
    final d = effectiveDeadline;
    return d != null && !AppClock.now().isBefore(d);
  }

  /// Faqat qat'iy chegara (maxsus test oxiri) sabab tugayaptimi.
  bool get endsByHardDeadline =>
      hardDeadline != null && (deadline == null || hardDeadline!.isBefore(deadline!));

  /// questionId -> asl harf.
  final Map<int, String> answers;

  /// Vaqti tugab yopilgan savollar.
  final Set<int> locked;

  /// questionId -> savol vaqti tugash payti (ms).
  final Map<int, int> questionDeadlines;
  int current;

  /// Test tugatilgan (natija yuborilishi kerak yoki yuborilmoqda).
  DateTime? finishedAt;

  /// Kitob/aralash testda javob darhol ko'rsatiladi; maxsus testda — yo'q (imtihon).
  bool get instantFeedback => kind != QuizKind.special;

  bool get isFinished => finishedAt != null;
  int get total => questions.length;
  int get answeredCount => questions.where((q) => (answers[q.id] ?? '').isNotEmpty).length;

  int get solved =>
      questions.where((q) => answers[q.id] != null && answers[q.id] == q.correct).length;

  double get percent => total == 0 ? 0 : solved * 100 / total;

  bool isAnswered(QuizQuestion q) => (answers[q.id] ?? '').isNotEmpty;
  bool isLocked(QuizQuestion q) => locked.contains(q.id);

  /// Javob berish mumkinmi?
  bool canAnswer(QuizQuestion q) {
    if (isFinished || isLocked(q)) return false;
    if (instantFeedback && isAnswered(q)) return false; // bir marta tanlanadi
    return true;
  }

  /// forceNext bo'lsa orqaga qaytish va erkin o'tish taqiqlanadi.
  bool get canNavigateFreely => !timing.forceNext;

  // ---------------- yaratish ----------------

  static QuizSession create({
    required String key,
    required QuizKind kind,
    required String title,
    required List<TestItem> items,
    required QuizTiming timing,
    int? testId,
    int? specialId,
    int passPercent = 60,
    DateTime? activeUntil,
  }) {
    final rnd = Random();
    final questions = <QuizQuestion>[];
    for (final it in items) {
      if (it.options.isEmpty) continue;
      final opts = it.options.entries.map((e) => QuizOption(e.key, e.value)).toList()..shuffle(rnd);
      final correct = it.options.containsKey(it.answer) ? it.answer : '';
      questions.add(QuizQuestion(id: it.id, text: it.question, options: opts, correct: correct));
    }
    questions.shuffle(rnd);
    final now = AppClock.now();
    return QuizSession(
      key: key,
      kind: kind,
      title: title,
      testId: testId,
      specialId: specialId,
      passPercent: passPercent,
      timing: timing,
      questions: questions,
      startedAt: now,
      deadline: timing.hasTotal ? now.add(Duration(seconds: timing.totalSeconds!)) : null,
      // Server faollik tugashini tekshiradi — 20 s zaxira bilan oldinroq yuboramiz.
      hardDeadline: activeUntil?.subtract(const Duration(seconds: 20)),
      ownerId: Session.user?.id,
    );
  }

  // ---------------- saqlash ----------------

  Future<void> save() => Storage.setQuiz(key, toJson());
  Future<void> discard() => Storage.setQuiz(key, null);

  static QuizSession? load(String key) {
    final j = Storage.quiz(key);
    if (j == null) return null;
    try {
      final s = QuizSession.fromJson(j);
      return s.questions.isEmpty || !s.belongsToCurrentUser ? null : s;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'kind': kind.name,
    'title': title,
    'testId': testId,
    'specialId': specialId,
    'passPercent': passPercent,
    'timing': timing.toJson(),
    'questions': questions.map((q) => q.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'hardDeadline': hardDeadline?.toIso8601String(),
    'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
    'locked': locked.toList(),
    'qd': questionDeadlines.map((k, v) => MapEntry(k.toString(), v)),
    'current': current,
    'finishedAt': finishedAt?.toIso8601String(),
    'ownerId': ownerId,
  };

  factory QuizSession.fromJson(Map<String, dynamic> j) {
    final answersRaw = asMap(j['answers']) ?? {};
    final qdRaw = asMap(j['qd']) ?? {};
    final qs = asMapList(j['questions']).map(QuizQuestion.fromJson).toList();
    return QuizSession(
      key: asStr(j['key']),
      kind: QuizKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => QuizKind.book),
      title: asStr(j['title'], 'Test'),
      testId: asInt(j['testId']),
      specialId: asInt(j['specialId']),
      passPercent: asInt(j['passPercent']) ?? 60,
      timing: QuizTiming.fromJson(asMap(j['timing']) ?? {}),
      questions: qs,
      startedAt: DateTime.tryParse(asStr(j['startedAt'])) ?? DateTime.now(),
      deadline: DateTime.tryParse(asStr(j['deadline'])),
      hardDeadline: DateTime.tryParse(asStr(j['hardDeadline'])),
      answers: answersRaw.map((k, v) => MapEntry(int.tryParse(k) ?? -1, asStr(v))),
      locked: (j['locked'] is List ? (j['locked'] as List) : const []).map(asInt).whereType<int>().toSet(),
      questionDeadlines: qdRaw.map((k, v) => MapEntry(int.tryParse(k) ?? -1, asInt(v) ?? 0)),
      current: (asInt(j['current']) ?? 0).clamp(0, qs.isEmpty ? 0 : qs.length - 1),
      finishedAt: DateTime.tryParse(asStr(j['finishedAt'])),
      ownerId: asInt(j['ownerId']),
    );
  }

  /// Saqlangan sessiya hozirgi savollar to'plamiga mosmi (admin testni o'zgartirmaganmi).
  bool matches(List<TestItem> items) {
    final a = questions.map((q) => q.id).toSet();
    final b = items.where((i) => i.options.isNotEmpty).map((i) => i.id).toSet();
    return a.length == b.length && a.containsAll(b);
  }

  // ---------------- taymer ----------------

  /// Umumiy qolgan vaqt (soniya). Qat'iy chegara ham hisobga olinadi.
  int? get totalRemaining {
    final d = effectiveDeadline;
    if (d == null) return null;
    return (d.difference(AppClock.now()).inMilliseconds / 1000).ceil();
  }

  /// Joriy savolga kirilganda chaqiriladi — savol taymerini boshlaydi.
  void enterCurrent() {
    if (!timing.hasPerQuestion || isFinished) return;
    final q = questions[current];
    if (isAnswered(q) || isLocked(q)) return;
    questionDeadlines.putIfAbsent(
      q.id,
      () => AppClock.nowMs() + timing.perQuestionSeconds! * 1000,
    );
  }

  /// Vaqti o'tgan (javobsiz) savollarni yopadi. O'zgarish bo'lsa true.
  bool lockExpiredQuestions() {
    if (!timing.hasPerQuestion) return false;
    final now = AppClock.nowMs();
    var changed = false;
    for (final q in questions) {
      final d = questionDeadlines[q.id];
      if (d != null && now >= d && !isAnswered(q) && !isLocked(q)) {
        locked.add(q.id);
        changed = true;
      }
    }
    return changed;
  }

  int? questionRemaining(QuizQuestion q) {
    if (!timing.hasPerQuestion || isAnswered(q) || isLocked(q)) return null;
    final d = questionDeadlines[q.id];
    if (d == null) return timing.perQuestionSeconds;
    return ((d - AppClock.nowMs()) / 1000).ceil();
  }

  // ---------------- natija ----------------

  /// POST /result uchun javoblar — eski ilova formati bilan mos:
  /// ko'rinadigan (aralashtirilgan) harflar bilan, `my_answer` maydoni bilan.
  List<Map<String, dynamic>> resultAnswers() {
    final list = <Map<String, dynamic>>[];
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final m = <String, dynamic>{
        'id': q.id,
        'number': i + 1,
        'question': q.text,
        'answer': q.displayLetter(q.correct),
        'my_answer': q.displayLetter(answers[q.id] ?? ''),
      };
      if (testId != null) m['test_id'] = testId;
      for (var k = 0; k < 4; k++) {
        m['answer_${answerLetters[k]}'] = k < q.options.length ? q.options[k].text : '';
      }
      list.add(m);
    }
    return list;
  }

  /// Natijani serverga yuboradi. Maxsus testda server hisoblagan ballni qaytaradi.
  Future<({int solved, int total, Map<int, String> key})> submit() async {
    switch (kind) {
      case QuizKind.special:
        final payload = <String, String>{
          for (final q in questions) q.id.toString(): answers[q.id] ?? '',
        };
        return Repo.submitSpecial(specialId!, payload);
      case QuizKind.book:
      case QuizKind.random:
        await Repo.postResult(
          testId: kind == QuizKind.book ? testId : null,
          type: kind == QuizKind.random ? 'RANDOM' : null,
          solved: solved,
          answers: resultAnswers(),
          startedAt: startedAt,
        );
        return (solved: solved, total: total, key: <int, String>{for (final q in questions) q.id: q.correct});
    }
  }
}
