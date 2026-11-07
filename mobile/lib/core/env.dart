import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env` dan o'qiladigan sozlamalar.
class Env {
  Env._();

  /// Masalan: http://90.156.197.252:3333/api/v1
  static String get baseUrl => _trim(dotenv.env['base_url'] ?? '');

  /// Statik fayllar (rasmlar) uchun: http://90.156.197.252:3333
  static String get domain => _trim(dotenv.env['domain'] ?? '');

  static String _trim(String v) {
    var s = v.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Backend qaytargan `/static/...` yo'lini to'liq URL ga aylantiradi.
  static String? imageUrl(String? path) {
    if (path == null || path.trim().isEmpty || path == 'null') return null;
    if (path.startsWith('http')) return Uri.encodeFull(path);
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.encodeFull('$domain$p');
  }
}
