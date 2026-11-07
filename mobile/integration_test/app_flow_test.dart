// Haqiqiy qurilma/emulyatorda to'liq ssenariy (lokal Docker backendga qarshi).
//
//   flutter test integration_test/app_flow_test.dart -d emulator-5554 \
//     --dart-define=TEST_PHONE=000000001 --dart-define=TEST_PASS=...
//
// mobile/.env: base_url=http://10.0.2.2:<port>/api/v1 (emulyatordan host'ga).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:test_app/features/books/book_widgets.dart';
import 'package:test_app/main.dart' as app;

const phone = String.fromEnvironment('TEST_PHONE');
const pass = String.fromEnvironment('TEST_PASS');

Future<void> pumpUntil(WidgetTester t, Finder f, {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 250));
    if (f.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Topilmadi: $f');
}

Future<void> tapAndWait(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pump(const Duration(milliseconds: 200));
  await t.tap(f.first, warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("to'liq ssenariy: login → bo'lim testi → natija → natijalarim → maxsus → liderlar", (t) async {
    expect(phone.isNotEmpty && pass.isNotEmpty, isTrue, reason: 'TEST_PHONE/TEST_PASS berilmagan');
    app.main();

    // ---- Login
    await pumpUntil(t, find.text('Kirish'));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), phone);
    await t.enterText(fields.at(1), pass);
    await t.pump();
    await tapAndWait(t, find.text('Kirish'));
    await pumpUntil(t, find.text('Liderlar'));

    // ---- Kitoblar -> kitob -> 1-bo'lim
    await tapAndWait(t, find.text('Kitoblar'));
    await pumpUntil(t, find.byType(BookCard));
    await tapAndWait(t, find.byType(BookCard));
    await pumpUntil(t, find.textContaining('ta test'));
    await tapAndWait(t, find.textContaining('ta test'));
    await pumpUntil(t, find.text('Testni boshlash'));
    await tapAndWait(t, find.text('Testni boshlash'));

    // ---- Test: har savolga 1-variantni tanlab oxirigacha
    await pumpUntil(t, find.byKey(const Key('quiz_next')));
    for (var i = 0; i < 200; i++) {
      await tapAndWait(t, find.byKey(const Key('quiz_opt_0')));
      final last = find.descendant(of: find.byKey(const Key('quiz_next')), matching: find.text('Yakunlash')).evaluate().isNotEmpty;
      await tapAndWait(t, find.byKey(const Key('quiz_next')));
      if (last) break;
    }
    // Tasdiqlash dialogi
    await pumpUntil(t, find.widgetWithText(TextButton, 'Yakunlash'));
    await tapAndWait(t, find.widgetWithText(TextButton, 'Yakunlash'));

    // ---- Natija ekrani (server qabul qildi)
    await pumpUntil(t, find.text("Javoblarni ko'rish"), timeout: const Duration(seconds: 40));
    expect(find.text("To'g'ri"), findsOneWidget);
    await tapAndWait(t, find.text("Javoblarni ko'rish"));
    await pumpUntil(t, find.textContaining('Hammasi'));
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));
    await tapAndWait(t, find.text('Yopish'));

    // Bo'lim sahifasida urinish paydo bo'ldi
    await pumpUntil(t, find.text('Urinishlar'));

    // ---- Orqaga -> Profil -> Mening natijalarim
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));
    await tapAndWait(t, find.text('Profil'));
    await pumpUntil(t, find.text('Mening natijalarim'));
    await tapAndWait(t, find.text('Mening natijalarim'));
    await pumpUntil(t, find.textContaining('Kitob ('));
    expect(find.textContaining('Urinish'), findsOneWidget);
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));

    // ---- Maxsus testlar (filtrlar bilan)
    await tapAndWait(t, find.text('Maxsus testlar'));
    await pumpUntil(t, find.textContaining('Faol ('));
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));

    // ---- Liderlar
    await tapAndWait(t, find.text('Liderlar').last);
    await pumpUntil(t, find.textContaining('(siz)'));
  });
}
