import 'dart:async';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/cookie_store.dart';

/// 阿里云 WAF JS 挑战执行页（参考 MT 客户端已验证方案）
/// 全屏加载论坛首页让 WebView 跑完混淆 JS，页面变为真实内容后收割 cookie 并自动关闭。
class WafChallengePage extends StatefulWidget {
  const WafChallengePage({super.key, required this.url});

  final String url;

  /// 打开挑战页，返回是否通过验证（通过时会同步 cookie 到原生请求池）
  static Future<bool> ensure(BuildContext context, String url) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WafChallengePage(url: url)),
    );
    return ok == true;
  }

  @override
  State<WafChallengePage> createState() => _WafChallengePageState();
}

class _WafChallengePageState extends State<WafChallengePage> {
  var _finished = false;
  Timer? _timeout;

  static bool isWafChallenge(String text) =>
      text.contains('Please enable JavaScript');

  @override
  void initState() {
    super.initState();
    // 兜底超时
    _timeout = Timer(const Duration(seconds: 30), () => _finish(false));
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _onLoadStop(InAppWebViewController controller) async {
    if (_finished) return;
    // 给混淆 JS 留执行时间；执行完页面会刷新为真实内容
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (_finished || !mounted) return;
    try {
      final html = await controller.evaluateJavascript(
        source: 'document.documentElement.innerHTML',
      );
      if (html is String && isWafChallenge(html)) {
        return; // 仍在挑战页，等待下一次加载
      }
    } catch (_) {}
    await _collectCookies();
    _finish(true);
  }

  /// 收割 WebView 的 cookie（含 WAF 验证 cookie）写回原生请求池
  Future<void> _collectCookies() async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      final jarCookies = <Cookie>[];
      for (final c in cookies) {
        final name = c.name.trim();
        final value = c.value;
        if (name.isEmpty || value.isEmpty) continue;
        try {
          // 不设 domain，由 saveFromResponse 的 Uri 归属，避免域匹配问题
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
    } catch (_) {}
  }

  void _finish(bool ok) {
    if (_finished) return;
    _finished = true;
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                initialSettings:
                    InAppWebViewSettings(userAgent: ApiClient.userAgent),
                onLoadStop: (controller, _) => _onLoadStop(controller),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                color: scheme.surface,
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '正在完成论坛安全验证…',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => _finish(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}