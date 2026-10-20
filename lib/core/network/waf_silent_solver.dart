import 'dart:async';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../config/website_constants.dart';
import '../utils/app_log.dart';
import 'cookie_store.dart';

/// WAF 静默验证：1×1 像素的后台 WebView 执行挑战 JS，用户完全无感知
class WafSilentSolver {
  WafSilentSolver._();

  static bool isWafChallenge(String html) =>
      html.contains('Please enable JavaScript');

  /// 后台完成挑战，通过返回 true（cookie 已同步到原生请求池）
  static Future<bool> solve(BuildContext context, String url) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return false;

    final completer = Completer<bool>();
    InAppWebViewController? controller;
    Timer? timeout;
    Timer? poll;
    var finished = false;
    late OverlayEntry entry;

    Future<void> finish(bool ok) async {
      if (finished) return;
      finished = true;
      timeout?.cancel();
      poll?.cancel();
      try {
        entry.remove();
      } catch (_) {}
      if (ok) {
        await _collectCookies();
      }
      if (!completer.isCompleted) completer.complete(ok);
    }

    entry = OverlayEntry(
      builder: (_) => Positioned(
        width: 1,
        height: 1,
        left: 0,
        top: 0,
        child: IgnorePointer(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialSettings:
                InAppWebViewSettings(userAgent: WebsiteConstants.desktopUserAgent),
            onWebViewCreated: (c) => controller = c,
          ),
        ),
      ),
    );
    overlay.insert(entry);

    timeout = Timer(const Duration(seconds: 30), () {
      logD('waf', '静默验证超时');
      finish(false);
    });

    poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      final c = controller;
      if (c == null || finished) return;
      try {
        final html = await c.evaluateJavascript(
          source: 'document.documentElement.innerHTML',
        );
        if (html is String && html.isNotEmpty && !isWafChallenge(html)) {
          logD('waf', '静默验证通过（页面 ${html.length} 字符）');
          await finish(true);
        }
      } catch (_) {}
    });

    return completer.future;
  }

  /// 收割 WebView 的 cookie（含 WAF 验证 cookie）写回原生请求池
  static Future<void> _collectCookies() async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      final jarCookies = <Cookie>[];
      for (final c in cookies) {
        final name = c.name.trim();
        final value = c.value;
        if (name.isEmpty || value.isEmpty) continue;
        try {
          jarCookies.add(Cookie(name, value)
            ..path = (c.path == null || c.path!.isEmpty) ? '/' : c.path!);
        } catch (_) {}
      }
      if (jarCookies.isNotEmpty) {
        await CookieStore.jar.saveFromResponse(
          Uri.parse(WebsiteConstants.serverBaseUrl),
          jarCookies,
        );
      }
      final header = cookies
          .where((c) => c.name.isNotEmpty)
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
      if (header.isNotEmpty) await CookieStore.setWebCookieHeader(header);
      logD('waf', '已同步 ${cookies.length} 个 cookie 到原生请求池');
    } catch (e) {
      logD('waf', '同步 cookie 失败: $e');
    }
  }
}