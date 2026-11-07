import '../core/api_client.dart';
import '../core/device.dart';
import '../core/storage.dart';
import 'models.dart';

/// Backend API (/api/v1) bilan ishlash — barcha so'rovlar shu yerda.
class Repo {
  Repo._();

  static final ApiClient _api = ApiClient.instance;

  // ---------------- auth ----------------

  /// POST /auth/login — STUDENT uchun qurilma ma'lumoti majburiy (aks holda 426).
  static Future<AppUser> login({required String phone, required String password}) async {
    final device = await DeviceData.payload();
    final data = await _api.post(
      '/auth/login',
      auth: false,
      data: {'login': phone, 'password': password, 'device': device},
    );
    final map = asMap(data);
    final token = map?['access_token']?.toString();
    final userJson = asMap(map?['user']);
    if (token == null || userJson == null) {
      throw ApiException("Serverdan noto'g'ri javob keldi");
    }
    final user = AppUser.fromJson(userJson);
    if (user.role != 'STUDENT') {
      throw ApiException("Bu ilova faqat o'quvchilar uchun. Admin/ustozlar web paneldan foydalanadi");
    }
    await Storage.setToken(token);
    await Storage.setUser(user.toStorage());
    return user;
  }

  /// GET /version — backenddagi APP_VERSION (minimal talab qilinadigan versiya).
  static Future<String?> serverVersion() async {
    final data = await _api.get('/version', auth: false);
    return asMap(data)?['version']?.toString();
  }

  // ---------------- profil ----------------

  static Future<GroupInfo?> myGroup() async {
    try {
      final data = await _api.get('/student/my-group');
      final m = asMap(data);
      return m == null ? null : GroupInfo.fromJson(m);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null; // guruhsiz o'quvchi
      rethrow;
    }
  }

  static Future<DeviceRecord?> myDevice() async {
    try {
      final m = asMap(await _api.get('/device/me'));
      return m == null ? null : DeviceRecord.fromJson(m);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<List<RateEntry>> rating() async {
    final list = asMapList(await _api.get('/student/rate'));
    final entries = list.map(RateEntry.fromJson).toList()
      ..sort((a, b) {
        final c = b.average.compareTo(a.average);
        return c != 0 ? c : b.attempts.compareTo(a.attempts);
      });
    return entries;
  }

  // ---------------- kontent ----------------

  static Future<List<Subject>> subjects() async =>
      asMapList(await _api.get('/subject/all')).map(Subject.fromJson).toList();

  static Future<List<Book>> books() async =>
      asMapList(await _api.get('/book/all')).map(Book.fromJson).toList();

  /// GET /section/all — barcha bo'limlar + test + mening natijalarim.
  static Future<List<SectionDetail>> sectionsAll() async =>
      asMapList(await _api.get('/section/all')).map(SectionDetail.fromJson).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  /// GET /section/:id — isBlocked/blockReason backend tomonidan hisoblanadi.
  static Future<SectionDetail> section(int id) async {
    final m = asMap(await _api.get('/section/$id'));
    if (m == null) throw ApiException("Bo'lim topilmadi", statusCode: 404);
    return SectionDetail.fromJson(m);
  }

  /// GET /test/:id — savollar (to'g'ri javob bilan).
  static Future<List<TestItem>> testItems(int testId) async {
    final m = asMap(await _api.get('/test/$testId'));
    final items = asMapList(m?['test_items']).map(TestItem.fromJson).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return items;
  }

  /// POST /test/random {sections, count}
  static Future<List<TestItem>> randomTest({required List<int> sectionIds, required int count}) async {
    final m = asMap(await _api.post('/test/random', data: {'sections': sectionIds, 'count': count}));
    return asMapList(m?['data']).map(TestItem.fromJson).toList();
  }

  // ---------------- maxsus testlar ----------------

  static Future<List<SpecialTest>> specialTests() async =>
      asMapList(await _api.get('/special-test/all')).map(SpecialTest.fromJson).toList();

  /// Faol bo'lmasa backend 403 "Test is not active" qaytaradi.
  static Future<SpecialTest> specialTest(int id) async {
    final m = asMap(await _api.get('/special-test/$id'));
    if (m == null) throw ApiException('Test topilmadi', statusCode: 404);
    return SpecialTest.fromJson(m);
  }

  /// POST /special-test/:id/submit {answers: {questionId: "A".."D" | ""}}
  /// Backend BARCHA savol ID lari bo'lishini talab qiladi.
  /// Javobda `answers_key` (savolId -> to'g'ri harf) keladi — ko'rib chiqish uchun.
  static Future<({int solved, int total, Map<int, String> key})> submitSpecial(int id, Map<String, String> answers) async {
    final m = asMap(await _api.post('/special-test/$id/submit', data: {'answers': answers}));
    final rawKey = asMap(m?['answers_key']) ?? const {};
    final key = <int, String>{
      for (final e in rawKey.entries)
        if (int.tryParse(e.key) != null) int.parse(e.key): asStr(e.value).toUpperCase(),
    };
    return (solved: asInt(m?['solved']) ?? 0, total: asInt(m?['total']) ?? answers.length, key: key);
  }

  // ---------------- natijalar ----------------

  /// POST /result — kitob (type=null) yoki aralash (type=RANDOM) test natijasi.
  static Future<void> postResult({
    int? testId,
    required String? type,
    required int solved,
    required List<Map<String, dynamic>> answers,
    required DateTime startedAt,
  }) async {
    // Backend: finishTime > server_now bo'lsa xato beradi — server soati bo'yicha olamiz.
    final finish = _api.serverNow.subtract(const Duration(seconds: 2));
    var start = startedAt.add(_api.serverNow.difference(DateTime.now()));
    if (start.isAfter(finish)) start = finish;
    await _api.post('/result', data: {
      if (testId != null) 'test_id': testId,
      if (type != null) 'type': type,
      'solved': solved,
      'answers': answers,
      'startTime': start.toUtc().toIso8601String(),
      'finishTime': finish.toUtc().toIso8601String(),
    });
  }

  static Future<List<ResultRecord>> results() async =>
      asMapList(await _api.get('/result/all')).map(ResultRecord.fromJson).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
}
