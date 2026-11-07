// Backend (NestJS + Prisma) javoblariga mos modellar.
// Barcha parse'lar null/tip xatolariga chidamli.

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return fallback;
}

String asStr(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  final s = v.toString();
  return s == 'null' ? fallback : s;
}

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<Map<String, dynamic>> asMapList(dynamic v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

Map<String, dynamic>? asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// "12. Savol matni" -> "Savol matni" (backend special testda ham shunday qiladi).
String cleanQuestion(String q) =>
    q.replaceFirst(RegExp(r'^\s*\d+\s*[.)]\s*'), '').trim();

const answerLetters = ['A', 'B', 'C', 'D'];

class AppUser {
  AppUser({required this.id, required this.name, required this.phone, required this.role, this.groupId});

  final int id;
  final String name;
  final String phone;
  final String role;
  final int? groupId;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], 'Foydalanuvchi'),
    phone: asStr(j['phone']),
    role: asStr(j['role'], 'STUDENT'),
    groupId: asInt(j['group_id']),
  );

  /// Parolni lokal saqlamaymiz.
  Map<String, dynamic> toStorage() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'group_id': groupId,
  };
}

/// Guruh taymer sozlamalari (admin panel bo'yicha):
/// * timeMinutes — aslida HAR BIR SAVOL uchun SEKUND;
/// * fullTime — butun test uchun MINUT;
/// * forceNextQuestion — savol vaqti tugasa keyingisiga majburiy o'tish.
class GroupInfo {
  GroupInfo({required this.id, required this.name, required this.hasTime, required this.perQuestionSeconds, required this.fullTimeMinutes, required this.forceNext});

  final int id;
  final String name;
  final bool hasTime;
  final int perQuestionSeconds;
  final int fullTimeMinutes;
  final bool forceNext;

  factory GroupInfo.fromJson(Map<String, dynamic> j) => GroupInfo(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], 'Guruh'),
    hasTime: asBool(j['hasTime']),
    perQuestionSeconds: asInt(j['timeMinutes']) ?? 0,
    fullTimeMinutes: asInt(j['fullTime']) ?? 0,
    forceNext: asBool(j['forceNextQuestion']),
  );

  QuizTiming get timing {
    if (!hasTime) return const QuizTiming();
    if (perQuestionSeconds > 0) {
      return QuizTiming(perQuestionSeconds: perQuestionSeconds, forceNext: forceNext);
    }
    if (fullTimeMinutes > 0) return QuizTiming(totalSeconds: fullTimeMinutes * 60);
    return const QuizTiming();
  }

  String get timingLabel => timing.label;
}

class QuizTiming {
  const QuizTiming({this.perQuestionSeconds, this.totalSeconds, this.forceNext = false});

  final int? perQuestionSeconds;
  final int? totalSeconds;
  final bool forceNext;

  bool get hasPerQuestion => (perQuestionSeconds ?? 0) > 0;
  bool get hasTotal => (totalSeconds ?? 0) > 0;
  bool get isTimed => hasPerQuestion || hasTotal;

  String get label {
    if (hasPerQuestion) {
      return 'Har savolga ${perQuestionSeconds}s${forceNext ? ' · majburiy o\'tish' : ''}';
    }
    if (hasTotal) {
      final m = totalSeconds! ~/ 60, s = totalSeconds! % 60;
      return 'Umumiy vaqt: ${m > 0 ? '$m daq' : ''}${s > 0 ? ' $s s' : ''}'.trim();
    }
    return 'Vaqt cheklanmagan';
  }

  Map<String, dynamic> toJson() => {
    'perQuestionSeconds': perQuestionSeconds,
    'totalSeconds': totalSeconds,
    'forceNext': forceNext,
  };

  factory QuizTiming.fromJson(Map<String, dynamic> j) => QuizTiming(
    perQuestionSeconds: asInt(j['perQuestionSeconds']),
    totalSeconds: asInt(j['totalSeconds']),
    forceNext: asBool(j['forceNext']),
  );
}

class Subject {
  Subject({required this.id, required this.name, this.image});

  final int id;
  final String name;
  final String? image;

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], 'Fan'),
    image: j['image']?.toString(),
  );
}

class Book {
  Book({required this.id, required this.name, this.image, this.subjectId, this.subjectName, required this.fullBlock, required this.stepBlock, required this.passingPercentage, required this.sections});

  final int id;
  final String name;
  final String? image;
  final int? subjectId;
  final String? subjectName;

  /// Kitob butunlay yopiq.
  final bool fullBlock;

  /// Bo'limlar ketma-ket ochiladi.
  final bool stepBlock;

  /// Keyingi bo'lim ochilishi uchun kerakli foiz.
  final int passingPercentage;
  final List<SectionBrief> sections;

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], 'Kitob'),
    image: j['image']?.toString(),
    subjectId: asInt(j['subject_id']),
    subjectName: asMap(j['subject'])?['name']?.toString(),
    fullBlock: asBool(j['fullBlock']),
    stepBlock: asBool(j['stepBlock'], true),
    passingPercentage: asInt(j['passingPercentage']) ?? 60,
    sections: asMapList(j['sections']).map(SectionBrief.fromJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id)),
  );
}

class SectionBrief {
  SectionBrief({required this.id, required this.name, this.bookId});

  final int id;
  final String name;
  final int? bookId;

  factory SectionBrief.fromJson(Map<String, dynamic> j) => SectionBrief(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], "Bo'lim"),
    bookId: asInt(j['book_id']),
  );
}

/// /section/all va /section/:id dagi bo'lim (test + mening natijalarim bilan).
class SectionDetail {
  SectionDetail({required this.id, required this.name, this.bookId, this.bookName, this.testId, required this.questionCount, required this.attempts, this.isBlocked = false, this.blockReason = '', this.book});

  final int id;
  final String name;
  final int? bookId;
  final String? bookName;
  final int? testId;
  final int questionCount;
  final List<Attempt> attempts;
  final bool isBlocked;
  final String blockReason;
  final Book? book;

  bool get hasTest => testId != null && questionCount > 0;

  /// Eng yaxshi natija foizi (backend blok mantiqi ham shuni ishlatadi).
  double get bestPercent {
    if (questionCount <= 0 || attempts.isEmpty) return 0;
    var best = 0.0;
    for (final a in attempts) {
      final p = a.solved * 100 / questionCount;
      if (p > best) best = p;
    }
    return best;
  }

  factory SectionDetail.fromJson(Map<String, dynamic> j) {
    final test = asMap(j['test']);
    final count = asMap(test?['_count']);
    final book = asMap(j['book']);
    return SectionDetail(
      id: asInt(j['id']) ?? 0,
      name: asStr(j['name'], "Bo'lim"),
      bookId: asInt(j['book_id']) ?? asInt(book?['id']),
      bookName: book?['name']?.toString(),
      testId: asInt(test?['id']),
      questionCount: asInt(count?['test_items']) ?? 0,
      attempts: asMapList(test?['results']).map(Attempt.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
      isBlocked: asBool(j['isBlocked']),
      blockReason: asStr(j['blockReason']),
      book: book == null ? null : Book.fromJson(book),
    );
  }
}

class Attempt {
  Attempt({required this.id, required this.solved, required this.date, this.answers});

  final int id;
  final int solved;
  final DateTime date;
  final dynamic answers;

  factory Attempt.fromJson(Map<String, dynamic> j) => Attempt(
    id: asInt(j['id']) ?? 0,
    solved: asInt(j['solved']) ?? 0,
    date: asDate(j['createdt']) ?? DateTime.now(),
    answers: j['answers'],
  );
}

/// Kitob testi savoli (TestItem). Backend to'g'ri javobni ham yuboradi.
class TestItem {
  TestItem({required this.id, required this.number, required this.question, required this.options, required this.answer});

  final int id;
  final int number;
  final String question;

  /// A..D -> matn (bo'sh variantlar tashlab yuboriladi).
  final Map<String, String> options;
  final String answer;

  factory TestItem.fromJson(Map<String, dynamic> j) {
    final opts = <String, String>{};
    for (final l in answerLetters) {
      final t = asStr(j['answer_$l']).trim();
      if (t.isNotEmpty) opts[l] = t;
    }
    return TestItem(
      id: asInt(j['id']) ?? 0,
      number: asInt(j['number']) ?? 0,
      question: cleanQuestion(asStr(j['question'])),
      options: opts,
      answer: asStr(j['answer']).trim().toUpperCase(),
    );
  }
}

class SpecialTest {
  SpecialTest({required this.id, required this.name, this.description, this.start, this.end, this.timePerQuestion, this.totalTime, required this.forceNext, required this.questionCount, required this.hasAttempted, required this.questions});

  final int id;
  final String name;
  final String? description;
  final DateTime? start;
  final DateTime? end;

  /// Sekund.
  final int? timePerQuestion;

  /// Sekund (admin hujjati bo'yicha).
  final int? totalTime;
  final bool forceNext;
  final int questionCount;
  final bool hasAttempted;
  final List<TestItem> questions;

  QuizTiming get timing {
    if ((timePerQuestion ?? 0) > 0) {
      return QuizTiming(perQuestionSeconds: timePerQuestion, forceNext: forceNext);
    }
    if ((totalTime ?? 0) > 0) return QuizTiming(totalSeconds: totalTime);
    return const QuizTiming();
  }

  int get realQuestionCount => questions.isNotEmpty ? questions.length : questionCount;

  SpecialStatus statusAt(DateTime now) {
    if (hasAttempted) return SpecialStatus.done;
    if (start != null && now.isBefore(start!)) return SpecialStatus.upcoming;
    if (end != null && now.isAfter(end!)) return SpecialStatus.expired;
    return SpecialStatus.active;
  }

  factory SpecialTest.fromJson(Map<String, dynamic> j) => SpecialTest(
    id: asInt(j['id']) ?? 0,
    name: asStr(j['name'], 'Maxsus test'),
    description: j['description']?.toString(),
    start: asDate(j['activation_start']),
    end: asDate(j['activation_end']),
    timePerQuestion: asInt(j['time_per_question']),
    totalTime: asInt(j['total_time']),
    forceNext: asBool(j['force_next_question']),
    questionCount: asInt(j['question_count']) ?? 0,
    hasAttempted: asBool(j['has_attempted']),
    questions: asMapList(j['questions']).map(TestItem.fromJson).toList()
      ..sort((a, b) => a.number.compareTo(b.number)),
  );
}

enum SpecialStatus { active, upcoming, expired, done }

enum ResultKind { book, random, special }

/// /result/all dagi natija.
class ResultRecord {
  ResultRecord({required this.id, required this.kind, required this.solved, required this.total, required this.date, required this.title, this.subtitle, this.answers, this.specialQuestions = const [], this.startTime, this.finishTime});

  final int id;
  final ResultKind kind;
  final int solved;
  final int total;
  final DateTime date;
  final String title;
  final String? subtitle;
  final dynamic answers;
  final List<TestItem> specialQuestions;
  final DateTime? startTime;
  final DateTime? finishTime;

  double get percent => total <= 0 ? 0 : solved * 100 / total;

  factory ResultRecord.fromJson(Map<String, dynamic> j) {
    final type = asStr(j['type']).toUpperCase();
    final test = asMap(j['test']);
    final special = asMap(j['specialTest']);
    final answers = j['answers'];
    final answersLen = answers is List ? answers.length : (answers is Map ? answers.length : 0);

    ResultKind kind;
    if (special != null || type.contains('SPECIAL')) {
      kind = ResultKind.special;
    } else if (type == 'RANDOM' || test == null) {
      kind = ResultKind.random;
    } else {
      kind = ResultKind.book;
    }

    String title;
    String? subtitle;
    int total;
    var specialQuestions = <TestItem>[];
    switch (kind) {
      case ResultKind.special:
        specialQuestions = asMapList(special?['questions']).map(TestItem.fromJson).toList()
          ..sort((a, b) => a.number.compareTo(b.number));
        title = asStr(special?['name'], 'Maxsus test');
        subtitle = 'Maxsus test';
        total = specialQuestions.isNotEmpty
            ? specialQuestions.length
            : (asInt(special?['question_count']) ?? answersLen);
      case ResultKind.random:
        title = 'Aralash test';
        subtitle = "Bir nechta bo'limdan";
        total = answersLen;
      case ResultKind.book:
        final section = asMap(test?['section']);
        final book = asMap(section?['book']);
        title = asStr(section?['name'], asStr(test?['name'], 'Test'));
        subtitle = book?['name']?.toString();
        total = asInt(asMap(test?['_count'])?['test_items']) ?? answersLen;
    }

    return ResultRecord(
      id: asInt(j['id']) ?? 0,
      kind: kind,
      solved: asInt(j['solved']) ?? 0,
      total: total,
      date: asDate(j['createdt']) ?? DateTime.now(),
      title: title,
      subtitle: subtitle,
      answers: answers,
      specialQuestions: specialQuestions,
      startTime: asDate(j['startTime']),
      finishTime: asDate(j['finishTime']),
    );
  }
}

/// Reyting qatori (/student/rate).
class RateEntry {
  RateEntry({required this.studentId, required this.name, required this.average, required this.attempts});

  final int studentId;
  final String name;
  final double average;
  final int attempts;

  factory RateEntry.fromJson(Map<String, dynamic> j) {
    final results = asMapList(j['results']);
    var sum = 0.0;
    var n = 0;
    for (final r in results) {
      final solved = asInt(r['solved']) ?? 0;
      int total = 0;
      final test = asMap(r['test']);
      final special = asMap(r['specialTest']);
      if (test != null) {
        total = asInt(asMap(test['_count'])?['test_items']) ?? 0;
      } else if (special != null) {
        total = asInt(special['question_count']) ?? 0;
      } else {
        final a = r['answers'];
        total = a is List ? a.length : (a is Map ? a.length : 0);
      }
      if (total <= 0) continue;
      sum += (solved / total).clamp(0, 1) * 100;
      n++;
    }
    return RateEntry(
      studentId: asInt(j['id']) ?? 0,
      name: asStr(j['name'], "O'quvchi"),
      average: n == 0 ? 0 : sum / n,
      attempts: n,
    );
  }
}

class DeviceRecord {
  DeviceRecord({required this.name, required this.type, this.appVersion, this.lastActive, this.createdAt});

  final String name;
  final String type;
  final String? appVersion;
  final DateTime? lastActive;
  final DateTime? createdAt;

  factory DeviceRecord.fromJson(Map<String, dynamic> j) => DeviceRecord(
    name: asStr(j['device_name'], 'Qurilma'),
    type: asStr(j['device_type']),
    appVersion: j['app_version']?.toString(),
    lastActive: asDate(j['last_active']),
    createdAt: asDate(j['createdAt']),
  );
}
