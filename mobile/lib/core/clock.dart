import 'api_client.dart';

/// Ilova bo'ylab yagona "hozir". Telefon soati xato yoki ataylab o'zgartirilgan
/// bo'lsa ham server vaqtiga yaqin (oxirgi javobdagi `Date` header bo'yicha).
class AppClock {
  AppClock._();

  static DateTime now() => ApiClient.instance.serverNow;
  static int nowMs() => now().millisecondsSinceEpoch;
}
