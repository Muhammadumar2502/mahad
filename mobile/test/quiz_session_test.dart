import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/core/storage.dart';
import 'package:test_app/data/models.dart';
import 'package:test_app/features/quiz/quiz_session.dart';
import 'package:test_app/features/quiz/review.dart';

List<TestItem> _items(int n) => List.generate(
  n,
  (i) => TestItem.fromJson({
    'id': 100 + i,
    'number': i + 1,
    'question': '${i + 1}. Savol $i',
    'answer_A': "To'g'ri $i",
    'answer_B': 'B$i',
    'answer_C': 'C$i',
    'answer_D': 'D$i',
    'answer': 'A',
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'base_url=http://localhost/api/v1\ndomain=http://localhost');
    final dir = await Directory.systemTemp.createTemp('quiz_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    await Storage.init();
    await Storage.setUser({'id': 7, 'name': 'Test', 'phone': '+998000000001', 'role': 'STUDENT'});
  });

  test("savol matnidan raqam olib tashlanadi, bo'sh variantlar tashlanadi", () {
    final it = TestItem.fromJson({'id': 1, 'question': '12. Nima?', 'answer_A': 'x', 'answer_B': '', 'answer': 'a'});
    expect(it.question, 'Nima?');
    expect(it.options.keys, ['A']);
    expect(it.answer, 'A');
  });

  test("aralashtirilgandan keyin ham to'g'ri javob matni mos", () {
    final s = QuizSession.create(key: 't1', kind: QuizKind.book, title: 'T', items: _items(30), timing: const QuizTiming(), testId: 5);
    expect(s.total, 30);
    expect(s.ownerId, 7);
    // To'g'ri javob har doim "To'g'ri ..." matnli variant bo'lishi kerak.
    for (final q in s.questions) {
      final correct = q.options.firstWhere((o) => o.original == q.correct);
      expect(correct.text.startsWith("To'g'ri"), isTrue);
    }
    // 30 savolda to'g'ri javob hammasi bir xil harfda qolmasligi kerak (aralashtirish ishlaydi).
    final letters = s.questions.map((q) => q.displayLetter(q.correct)).toSet();
    expect(letters.length, greaterThan(1));
  });

  test('ball va POST /result javoblari ko\'rinadigan harflarda izchil', () {
    final s = QuizSession.create(key: 't2', kind: QuizKind.book, title: 'T', items: _items(4), timing: const QuizTiming(), testId: 9);
    s.answers[s.questions[0].id] = s.questions[0].correct; // to'g'ri
    final wrong = s.questions[1].options.firstWhere((o) => o.original != s.questions[1].correct);
    s.answers[s.questions[1].id] = wrong.original; // xato
    expect(s.solved, 1);
    expect(s.answeredCount, 2);

    final payload = s.resultAnswers();
    expect(payload.length, 4);
    expect(payload[0]['my_answer'], payload[0]['answer']);
    expect(payload[1]['my_answer'], isNot(payload[1]['answer']));
    expect(payload[2]['my_answer'], '');
    expect(payload[0]['test_id'], 9);
    // Ko'rinadigan harf bo'yicha matn ham to'g'ri saqlangan
    final l = payload[0]['answer'] as String;
    expect((payload[0]['answer_$l'] as String).startsWith("To'g'ri"), isTrue);

    // Serverdan qaytgan yozuvdan ko'rib chiqish to'g'ri tiklanadi
    final rec = ResultRecord.fromJson({'id': 1, 'type': null, 'solved': 1, 'answers': payload, 'test': {'_count': {'test_items': 4}}});
    final review = ReviewData.fromRecord(rec)!;
    expect(review.correct, 1);
    expect(review.items[2].isEmpty, isTrue);
  });

  test('saqlash va qayta tiklash (JSON) holatni yo\'qotmaydi', () async {
    final s = QuizSession.create(
      key: 't3',
      kind: QuizKind.special,
      title: 'Maxsus',
      items: _items(3),
      timing: const QuizTiming(perQuestionSeconds: 20, forceNext: true),
      specialId: 49,
      activeUntil: DateTime.now().add(const Duration(hours: 1)),
    );
    s.answers[s.questions[0].id] = 'B';
    s.locked.add(s.questions[1].id);
    s.current = 2;
    await s.save();
    final r = QuizSession.load('t3')!;
    expect(r.kind, QuizKind.special);
    expect(r.answers[s.questions[0].id], 'B');
    expect(r.isLocked(r.questions[1]), isTrue);
    expect(r.current, 2);
    expect(r.timing.forceNext, isTrue);
    expect(r.hardDeadline, isNotNull);
    expect(r.instantFeedback, isFalse);
    await r.discard();
    expect(QuizSession.load('t3'), isNull);
  });

  test('umumiy taymer va qat\'iy chegara', () {
    final s = QuizSession.create(
      key: 't4',
      kind: QuizKind.special,
      title: 'X',
      items: _items(2),
      timing: const QuizTiming(totalSeconds: 3600),
      specialId: 1,
      activeUntil: DateTime.now().add(const Duration(minutes: 5)),
    );
    // Maxsus test 5 daqiqada tugaydi — 1 soatlik vaqt emas, muddat ustun.
    expect(s.endsByHardDeadline, isTrue);
    expect(s.totalRemaining!, lessThanOrEqualTo(5 * 60 - 20));
    expect(s.isExpired, isFalse);

    final expired = QuizSession.create(
      key: 't5',
      kind: QuizKind.special,
      title: 'X',
      items: _items(2),
      timing: const QuizTiming(),
      specialId: 1,
      activeUntil: DateTime.now().add(const Duration(seconds: 10)), // 20 s zaxiradan kam
    );
    expect(expired.isExpired, isTrue);
  });

  test("savol taymeri: vaqti o'tgan javobsiz savol yopiladi, javob berilgani — yo'q", () {
    final s = QuizSession.create(
      key: 't6',
      kind: QuizKind.book,
      title: 'X',
      items: _items(3),
      timing: const QuizTiming(perQuestionSeconds: 5),
    );
    s.enterCurrent();
    final q0 = s.questions[0];
    expect(s.questionRemaining(q0), inInclusiveRange(4, 5));
    // Vaqtni o'tkazib yuboramiz
    s.questionDeadlines[q0.id] = DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch;
    s.questionDeadlines[s.questions[1].id] = DateTime.now().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch;
    s.answers[s.questions[1].id] = s.questions[1].correct;
    expect(s.lockExpiredQuestions(), isTrue);
    expect(s.isLocked(q0), isTrue);
    expect(s.isLocked(s.questions[1]), isFalse);
    expect(s.canAnswer(q0), isFalse);
    // Kitob testida javob bir marta tanlanadi
    expect(s.canAnswer(s.questions[1]), isFalse);
  });

  test("boshqa o'quvchining sessiyasi ko'rinmaydi", () async {
    final s = QuizSession.create(key: 't7', kind: QuizKind.random, title: 'X', items: _items(2), timing: const QuizTiming());
    await s.save();
    expect(QuizSession.load('t7'), isNotNull);
    await Storage.setUser({'id': 8, 'name': 'Boshqa', 'phone': '+998000000002', 'role': 'STUDENT'});
    expect(QuizSession.load('t7'), isNull);
    await Storage.setUser({'id': 7, 'name': 'Test', 'phone': '+998000000001', 'role': 'STUDENT'});
    await s.discard();
  });

  test('maxsus test natijasi va reyting hisobi', () {
    final rec = ResultRecord.fromJson({
      'id': 3,
      'type': 'SpecialTest',
      'solved': 1,
      'answers': {'10': 'A', '11': ''},
      'specialTest': {
        'name': 'M',
        'questions': [
          {'id': 10, 'number': 1, 'question': 'q1', 'answer_A': 'a', 'answer_B': 'b', 'answer': 'A'},
          {'id': 11, 'number': 2, 'question': 'q2', 'answer_A': 'a', 'answer_B': 'b', 'answer': 'B'},
        ],
      },
    });
    expect(rec.kind, ResultKind.special);
    expect(rec.total, 2);
    final rv = ReviewData.fromRecord(rec)!;
    expect(rv.correct, 1);

    final rate = RateEntry.fromJson({
      'id': 1,
      'name': 'A',
      'results': [
        {'solved': 5, 'test': {'_count': {'test_items': 10}}},
        {'solved': 2, 'specialTest': {'question_count': 2}},
        {'solved': 3, 'answers': [1, 2, 3, 4]},
      ],
    });
    expect(rate.attempts, 3);
    expect(rate.average.toStringAsFixed(1), '75.0'); // (50 + 100 + 75) / 3
  });

  test('versiya solishtirish', () async {
    // DeviceData import qilmaslik uchun oddiy tekshiruv: GroupInfo taymer mantiqi
    final g = GroupInfo.fromJson({'id': 5, 'name': 'G', 'hasTime': 1, 'timeMinutes': 0, 'fullTime': 30, 'forceNextQuestion': 0});
    expect(g.timing.totalSeconds, 1800);
    expect(g.timing.hasPerQuestion, isFalse);
    final g2 = GroupInfo.fromJson({'id': 5, 'hasTime': true, 'timeMinutes': 15, 'fullTime': 30, 'forceNextQuestion': true});
    expect(g2.timing.perQuestionSeconds, 15);
    expect(g2.timing.forceNext, isTrue);
    expect(GroupInfo.fromJson({'hasTime': false, 'fullTime': 30}).timing.isTimed, isFalse);
  });
}
