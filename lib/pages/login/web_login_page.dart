import 'dart:async';
import 'dart:convert';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/account/user_data_repo.dart';
import '../../core/config/website_constants.dart';
import '../../core/network/cookie_store.dart';
import '../../data/repository/login_repository.dart';

/// 内嵌网页登录（52pojie 的验证码是「点击验证」人机验证，需在网页内完成）
/// 登录成功判定（双重）：
/// 1) 页面出现 Discuz 登录态 DOM（#um / .vwmy）
/// 2) cookie 中存在 *_auth 且非空
/// 命中即同步 Cookie、落登录态并自动返回。
class WebLoginPage extends StatefulWidget {
  const WebLoginPage({
    super.key,
    this.username,
    this.password,
    this.questionId = '0',
    this.answer = '',
  });

  final String? username;
  final String? password;
  final String? questionId;
  final String? answer;

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  InAppWebViewController? _controller;
  var _checking = false;
  var _done = false;
  var _filledForUrl = '';
  Timer? _timer;

  static const _jsLoggedCheck = '''
(function(){
  try {
    if (document.querySelector('#um, .vwmy')) return 'OK';
    var t = document.body ? document.body.innerText : '';
    if (t.indexOf('欢迎您回来') >= 0) return 'OK';
  } catch(e) {}
  return '';
})();
''';

  @override
  void initState() {
    super.initState();
    // 轮询检测：登录成功后无需等待页面跳转即可识别
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _checkLogin());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fillForm(Uri? url) async {
    final controller = _controller;
    if (controller == null || widget.username == null || widget.password == null) return;
    final urlStr = url?.toString() ?? '';
    if (!urlStr.contains('action=login') || _filledForUrl == urlStr) return;
    _filledForUrl = urlStr;
    final js = '''
(function(){
  try {
    var u=document.querySelector('input[name="username"]');
    if(u){u.value=${jsonEncode(widget.username)};}
    var p=document.querySelector('input[name="password"]');
    if(p){p.value=${jsonEncode(widget.password)};}
    var a=document.querySelector('input[name="answer"]');
    if(a && ${jsonEncode(widget.answer ?? '')} !== ''){a.value=${jsonEncode(widget.answer ?? '')};}
    var q=document.querySelector('select[name="questionid"]');
    if(q){q.value=${jsonEncode(widget.questionId ?? '0')};}
  } catch(e) {}
})();
''';
    try {
      await controller.evaluateJavascript(source: js);
    } catch (_) {}
  }

  Future<void> _checkLogin() async {
    if (_checking || _done) return;
    _checking = true;
    try {
      // 1) 页面登录态 DOM
      var logged = false;
      final controller = _controller;
      if (controller != null) {
        try {
          final r = await controller.evaluateJavascript(source: _jsLoggedCheck);
          if ((r?.toString() ?? '').contains('OK')) logged = true;
        } catch (_) {}
      }

      // 2) cookie 登录态（逐个安全转换，避免个别非法 cookie 中断）
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      final jarCookies = <Cookie>[];
      for (final c in cookies) {
        if (c.name.endsWith('_auth') && c.value.isNotEmpty) logged = true;
        try {
          jarCookies.add(Cookie(c.name, c.value)
            ..domain = (c.domain?.isNotEmpty == true) ? c.domain! : 'www.52pojie.cn'
            ..path = (c.path?.isNotEmpty == true) ? c.path! : '/');
        } catch (_) {}
      }
      if (!logged) return;

      if (jarCookies.isNotEmpty) {
        try {
          await CookieStore.jar.saveFromResponse(
            Uri.parse(WebsiteConstants.serverBaseUrl),
            jarCookies,
          );
        } catch (_) {}
      }
      _done = true;
      UserDataRepo.setLoggedIn(true);
      unawaited(LoginRepository.instance.verifyLoggedInAfterWebLogin());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录验证'),
        actions: [
          TextButton(
            onPressed: _checkLogin,
            child: const Text('我已完成登录', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF7E6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Text(
              '账号密码已自动填写，请点击页面中的「点击验证」完成人机验证，再点「登录」。登录成功后会自动返回。',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6D3B)),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(WebsiteConstants.serverBaseUrl + WebsiteConstants.loginQuery),
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStop: (controller, url) async {
                _controller = controller;
                await _fillForm(url);
                await _checkLogin();
              },
            ),
          ),
        ],
      ),
    );
  }
}