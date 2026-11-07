import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'storage.dart';

/// Joriy foydalanuvchi, guruh sozlamalari va global navigatsiya.
class Session {
  Session._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static AppUser? get user {
    final j = Storage.user;
    return j == null ? null : AppUser.fromJson(j);
  }

  static bool get isLoggedIn => Storage.token != null && Storage.user != null;

  static GroupInfo? _group;
  static DateTime? _groupLoadedAt;

  /// Guruh (taymer sozlamalari). 2 daqiqa keshlanadi — admin o'zgartirsa tez yangilanadi.
  static Future<GroupInfo?> group({bool force = false}) async {
    final fresh = _groupLoadedAt != null &&
        DateTime.now().difference(_groupLoadedAt!) < const Duration(minutes: 2);
    if (!force && fresh) return _group;
    _group = await Repo.myGroup();
    _groupLoadedAt = DateTime.now();
    return _group;
  }

  static GroupInfo? get cachedGroup => _group;

  static Future<void> clear() async {
    _group = null;
    _groupLoadedAt = null;
    await Storage.clearSession();
  }

  static void toast(String message, {bool error = false}) {
    final m = messengerKey.currentState;
    if (m == null) return;
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFE5484D) : const Color(0xFF2F8F55),
          duration: Duration(seconds: error ? 4 : 2),
        ),
      );
  }
}
