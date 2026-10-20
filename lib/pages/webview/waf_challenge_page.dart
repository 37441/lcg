import 'dart:async';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/config/website_constants.dart';
import '../../core/network/cookie_store.dart';

/// 阿里云 WAF JS 挑战穿透页
/// WebView 加载目标页自动执行挑战脚本，通过后同步全部 Cookie 并返回 true
class WafChallengePage extends StatefulWidget {
  const WafChallengePage({super.key, required this.url});

  final String url;

  /// 打开挑战页，返回是否通过验证
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
  InAppWebViewController? _controller;
  var _done = false;
  Timer? _timer;
  Timer? _timeout;

  static const _jsState = '''
(function(){
  try {
    if (!document.body) return 'WAIT';
    var t = document.body.innerText || '';
    if (!t.trim()) return 'WAIT';
    return t.indexOf('Please enable JavaScript') >= 0 ? 'WAF' : 'OK';
  } catch(e) { return 'WAIT'; }
})();
''';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _check());
    _timeout = Timer(const Duration(seconds: 25), () {
      if (mounted && !_done) Navigator.of(context).pop(false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final controller = _controller;
    if (controller == null || _done) return;
    try {
      final r = await controller.evaluateJavascript(source: _jsState);
      if ((r?.toString() ?? '') != 'OK') return;
      // 挑战已通过：同步全部 Cookie 到原生池
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      final jarCookies = <Cookie>[];
      for (final c in cookies) {
        try {
          jarCookies.add(Cookie(c.name, c.value)
            ..domain = (c.domain?.isNotEmpty == true) ? c.domain! : 'www.52pojie.cn'
            ..path = (c.path?.isNotEmpty == true) ? c.path! : '/');
        } catch (_) {}
      }
      if (jarCookies.isNotEmpty) {
        try {
          await CookieStore.jar.saveFromResponse(
            Uri.parse(WebsiteConstants.serverBaseUrl),
            jarCookies,
          );
        } catch (_) {}
      }
      try {
        final header = cookies.map((c) => '${c.name}=${c.value}').join('; ');
        if (header.isNotEmpty) await CookieStore.setWebCookieHeader(header);
      } catch (_) {}
      _done = true;
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('安全验证')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF7E6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              '正在通过站点安全验证，请稍候（自动完成，无需操作）…',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6D3B)),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStop: (controller, url) async {
                _controller = controller;
                await _check();
              },
            ),
          ),
        ],
      ),
    );
  }
}