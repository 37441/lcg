import 'dart:convert';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/config/website_constants.dart';
import '../../core/network/cookie_store.dart';
import '../../data/repository/login_repository.dart';

/// 内嵌网页登录（52pojie 的验证码是「点击验证」人机验证，需在网页内完成）
/// - 传入账号密码时自动填充表单，用户只需点击验证并登录
/// - 任意页面加载后自动同步 Cookie 到原生池并用个人页校验登录态
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
  var _checking = false;
  var _done = false;

  Future<void> _fillForm(InAppWebViewController controller, Uri? url) async {
    if (widget.username == null || widget.password == null) return;
    if (url == null || !url.toString().contains('action=login')) return;
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

  /// 同步 WebView Cookie → 原生 cookie 池，并用个人页校验登录态
  Future<void> _checkLogin() async {
    if (_checking || _done) return;
    _checking = true;
    try {
      final cookies =
          await CookieManager.instance().getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      if (cookies.isEmpty) return;
      final jarCookies = <Cookie>[
        for (final c in cookies)
          Cookie(c.name, c.value)
            ..domain = c.domain ?? 'www.52pojie.cn'
            ..path = c.path ?? '/',
      ];
      await CookieStore.jar.saveFromResponse(
        Uri.parse(WebsiteConstants.serverBaseUrl),
        jarCookies,
      );
      final result = await LoginRepository.instance.verifyLoggedInAfterWebLogin();
      if (result is LoginSuccess && mounted) {
        _done = true;
        Navigator.of(context).pop(true);
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onLoadStop: (controller, url) async {
                await _fillForm(controller, url);
                await _checkLogin();
              },
            ),
          ),
        ],
      ),
    );
  }
}