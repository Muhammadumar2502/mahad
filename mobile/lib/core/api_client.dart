import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'env.dart';
import 'storage.dart';

enum ApiErrorKind { network, timeout, http, unknown }

/// Ilova bo'ylab yagona xato turi. [message] doim foydalanuvchiga
/// ko'rsatishga tayyor (o'zbekcha) matn.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.kind = ApiErrorKind.http});

  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  bool get isNetwork =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => message;
}

typedef MessageCallback = void Function(String message);

/// Dio ustidagi klient:
/// * tokenni avtomatik qo'shadi;
/// * backend xatolarini [ApiException] ga aylantiradi;
/// * 401 (sessiya/qurilma) va 426 (eski versiya) ni global ushlaydi;
/// * server soatini (`Date` header) kuzatadi — natija vaqti uchun.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Storage.token;
          if (options.extra['auth'] != false && token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _trackServerTime(response.headers);
          handler.next(response);
        },
        onError: (error, handler) {
          final r = error.response;
          if (r != null) _trackServerTime(r.headers);
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// Sessiya tugaganda (401) chaqiriladi. App darajasida o'rnatiladi.
  MessageCallback? onSessionExpired;

  /// Backend "eski versiya" (426) desa chaqiriladi.
  MessageCallback? onUpgradeRequired;

  Duration _serverOffset = Duration.zero;

  /// Telefon soati xato bo'lsa ham server vaqtiga yaqin "hozir".
  DateTime get serverNow => DateTime.now().add(_serverOffset);

  void _trackServerTime(Headers headers) {
    final raw = headers.value('date');
    if (raw == null) return;
    try {
      final server = HttpDate.parse(raw);
      _serverOffset = server.difference(DateTime.now());
    } catch (_) {}
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) => _send(
    () => _dio.get(
      path,
      queryParameters: query,
      options: Options(extra: {'auth': auth}),
    ),
    auth: auth,
  );

  Future<dynamic> post(String path, {Object? data, bool auth = true}) => _send(
    () => _dio.post(path, data: data, options: Options(extra: {'auth': auth})),
    auth: auth,
  );

  Future<dynamic> _send(
    Future<Response<dynamic>> Function() call, {
    required bool auth,
  }) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      final ex = _map(e);
      if (kDebugMode) {
        debugPrint('API ${e.requestOptions.method} ${e.requestOptions.path} '
            '-> ${ex.statusCode} ${ex.message}');
      }
      if (ex.statusCode == 426) {
        onUpgradeRequired?.call(ex.message);
      } else if (ex.statusCode == 401 && auth && Storage.token != null) {
        onSessionExpired?.call(ex.message);
      }
      throw ex;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        "Kutilmagan xatolik yuz berdi",
        kind: ApiErrorKind.unknown,
      );
    }
  }

  ApiException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          "Server javob bermadi. Internetni tekshirib, qayta urinib ko'ring",
          kind: ApiErrorKind.timeout,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          "Internet aloqasi yo'q yoki server ishlamayapti",
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return ApiException(
          _messageFrom(code, e.response?.data),
          statusCode: code,
        );
      case DioExceptionType.cancel:
        return ApiException("So'rov bekor qilindi", kind: ApiErrorKind.unknown);
      default:
        if (e.error is SocketException) {
          return ApiException(
            "Internet aloqasi yo'q",
            kind: ApiErrorKind.network,
          );
        }
        return ApiException(
          "Kutilmagan xatolik yuz berdi",
          kind: ApiErrorKind.unknown,
        );
    }
  }

  static String _messageFrom(int? code, dynamic data) {
    String? raw;
    if (data is Map) {
      final m = data['message'];
      if (m is String) {
        raw = m;
      } else if (m is List && m.isNotEmpty) {
        raw = m.map((x) => x.toString()).join('\n');
      } else if (m is Map && m['message'] is String) {
        raw = m['message'] as String;
      }
      raw ??= data['error']?.toString();
    } else if (data is String && data.isNotEmpty && data.length < 200) {
      raw = data;
    }
    return translate(raw, code);
  }

  /// Backenddagi inglizcha xabarlarni o'zbekchaga o'giradi.
  static String translate(String? raw, int? code) {
    const map = {
      'Incorrect Credentials': "Telefon raqam yoki parol noto'g'ri",
      'Unauthorized': "Sessiya muddati tugadi. Iltimos, qaytadan kiring",
      'Test is not active': 'Bu test hozir faol emas',
      'Access denied': "Sizga bu testga ruxsat berilmagan",
      'All questions must be answered':
          "Barcha savollar yuborilmadi. Qayta urinib ko'ring",
      'Internal Server Error': "Serverda xatolik. Birozdan so'ng urinib ko'ring",
      'Student has no group assigned': 'Siz hech qaysi guruhga biriktirilmagansiz',
      'Special test not found': 'Test topilmadi',
      'Test not found': 'Test topilmadi',
      'section not found': "Bo'lim topilmadi",
      'Book not found': 'Kitob topilmadi',
      'Forbidden': "Ruxsat berilmagan",
    };
    if (raw != null && raw.trim().isNotEmpty) {
      return map[raw.trim()] ?? raw.trim();
    }
    switch (code) {
      case 400:
        return "So'rov noto'g'ri";
      case 401:
        return map['Unauthorized']!;
      case 403:
        return 'Ruxsat berilmagan';
      case 404:
        return "Ma'lumot topilmadi";
      case 426:
        return 'Iltimos, ilovaning oxirgi versiyasini yuklab oling';
      default:
        return "Serverda xatolik (${code ?? '?'})";
    }
  }
}
