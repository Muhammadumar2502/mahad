import 'package:get_storage/get_storage.dart';

/// Lokal saqlash (GetStorage) ustidagi tipli o'ram.
class Storage {
  Storage._();

  static final GetStorage _box = GetStorage();

  static Future<void> init() => GetStorage.init();

  static const _token = 'access_token';
  static const _user = 'user';
  static const _deviceId = 'device_identifier';
  static const _saved = 'saved_sections_v2';
  static const _quizPrefix = 'quiz_session_v2_';

  // --- auth ---
  static String? get token => _box.read<String>(_token);
  static Future<void> setToken(String? v) =>
      v == null ? _box.remove(_token) : _box.write(_token, v);

  static Map<String, dynamic>? get user {
    final v = _box.read(_user);
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  static Future<void> setUser(Map<String, dynamic>? v) =>
      v == null ? _box.remove(_user) : _box.write(_user, v);

  // --- device (zaxira identifikator) ---
  static String? get deviceId => _box.read<String>(_deviceId);
  static Future<void> setDeviceId(String v) => _box.write(_deviceId, v);

  // --- saqlangan bo'limlar ---
  static Map<String, dynamic> get saved {
    final v = _box.read(_saved);
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }

  static Future<void> setSaved(Map<String, dynamic> v) => _box.write(_saved, v);

  // --- test sessiyalari (davom ettirish uchun) ---
  static Map<String, dynamic>? quiz(String key) {
    final v = _box.read(_quizPrefix + key);
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  static Future<void> setQuiz(String key, Map<String, dynamic>? v) => v == null
      ? _box.remove(_quizPrefix + key)
      : _box.write(_quizPrefix + key, v);

  /// Barcha saqlangan (tugallanmagan) test sessiyalari.
  static List<Map<String, dynamic>> allQuizzes() {
    final out = <Map<String, dynamic>>[];
    for (final k in _box.getKeys<Iterable<dynamic>>().whereType<String>()) {
      if (!k.startsWith(_quizPrefix)) continue;
      final v = _box.read(k);
      if (v is Map) out.add(Map<String, dynamic>.from(v));
    }
    return out;
  }

  static Future<void> clearAllQuizzes() async {
    final keys = _box.getKeys<Iterable<dynamic>>().whereType<String>().where(
      (k) => k.startsWith(_quizPrefix),
    );
    for (final k in keys.toList()) {
      await _box.remove(k);
    }
  }

  /// Chiqishda: token, user va test sessiyalari o'chadi.
  /// Qurilma identifikatori va saqlanganlar qoladi.
  static Future<void> clearSession({bool keepQuizzes = false}) async {
    await _box.remove(_token);
    if (!keepQuizzes) {
      await _box.remove(_user);
      await clearAllQuizzes();
    }
  }
}
