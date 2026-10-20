import 'package:cookie_jar/cookie_jar.dart';

/// Cookie 池 —— 对应原生 CookieUtils.kt（SharedPreferences → cookie_jar 文件持久化）
class CookieStore {
  CookieStore._();

  static CookieJar? _jar;

  static CookieJar get jar => _jar!;

  static bool get isReady => _jar != null;

  static void init(CookieJar jar) => _jar = jar;

  /// 取某个 key 的 cookie 值（Discuz 的 cookie 带随机前缀，如 htVC_2132_saltkey）
  static Future<String?> valueOf(String name) async {
    final jar = _jar;
    if (jar == null) return null;
    try {
      final list = await jar.loadForRequest(Uri.parse('https://www.52pojie.cn/'));
      for (final c in list) {
        if (c.name == name || c.name.endsWith('_$name')) return c.value;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clearAll() async {
    final jar = _jar;
    if (jar != null) {
      await jar.deleteAll();
    }
  }
}