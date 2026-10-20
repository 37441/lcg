import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cookie 池 —— cookie_jar 持久化 + WebView 同步的原始 Cookie 头
class CookieStore {
  CookieStore._();

  static CookieJar? _jar;
  static const _kWebCookie = 'web_cookie_header';
  static String? _webCookieHeader;

  static CookieJar get jar => _jar!;

  static bool get isReady => _jar != null;

  static void init(CookieJar jar) => _jar = jar;

  /// WebView 登录同步来的原始 Cookie 头（优先用于原生请求，避免域匹配问题）
  static String? get webCookieHeader => _webCookieHeader;

  static Future<void> loadWebCookieHeader() async {
    final p = await SharedPreferences.getInstance();
    _webCookieHeader = p.getString(_kWebCookie);
  }

  static Future<void> setWebCookieHeader(String? value) async {
    _webCookieHeader = value;
    final p = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await p.remove(_kWebCookie);
    } else {
      await p.setString(_kWebCookie, value);
    }
  }

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
    await setWebCookieHeader(null);
  }
}