import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'storage.dart';

/// Login so'rovida yuboriladigan qurilma ma'lumoti (backend: LoginDeviceDto).
class DeviceData {
  DeviceData._();

  static String appVersion = '0.0.0';
  static String buildNumber = '0';
  static Map<String, dynamic>? _cached;

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {}
  }

  /// Backend kutgan payload:
  /// device_name, device_type (ANDROID|IOS), device_identifier, user_agent, app_version
  static Future<Map<String, dynamic>> payload() async {
    if (_cached != null) return _cached!;
    final plugin = DeviceInfoPlugin();
    String name = 'Unknown device';
    String type = Platform.isIOS ? 'IOS' : 'ANDROID';
    String? identifier;
    String userAgent = Platform.operatingSystem;

    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        name = '${_cap(a.manufacturer)} ${a.model}'.trim();
        userAgent = 'Android ${a.version.release}';
        // ANDROID_ID: qurilma + imzo kaliti bo'yicha barqaror,
        // OS yangilanishida o'zgarmaydi (eski ilova build ID ishlatgan edi).
        identifier = await const AndroidId().getId();
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        name = i.utsname.machine.isNotEmpty ? '${i.name} (${i.utsname.machine})' : i.name;
        userAgent = 'iOS ${i.systemVersion}';
        identifier = i.identifierForVendor;
      }
    } catch (_) {}

    identifier = (identifier == null || identifier.isEmpty)
        ? _fallbackId()
        : identifier;

    _cached = {
      'device_name': name.isEmpty ? 'Unknown device' : name,
      'device_type': type,
      'device_identifier': identifier,
      'user_agent': userAgent,
      'app_version': appVersion,
    };
    return _cached!;
  }

  static String _fallbackId() {
    final saved = Storage.deviceId;
    if (saved != null && saved.isNotEmpty) return saved;
    final r = Random.secure();
    final hex = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final id = 'app-$hex';
    Storage.setDeviceId(id);
    return id;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// "1.3.6" va "1.4.0" ni solishtiradi: a<b bo'lsa manfiy.
  static int compareVersions(String a, String b) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((x) => int.tryParse(x.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parse(a), pb = parse(b);
    for (var i = 0; i < max(pa.length, pb.length); i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
