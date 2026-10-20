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
/// - 传入账号密码时自动填充表单，用户只需点击验证并登录
/// - 通过 Discuz 的 *_auth cookie 判定登录成功（不依赖页面跳转），成功后同步 Cookie 并自动返回
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 轮询检测：即使页面未触发 onLoadStop（AJAX 登录）也能识别登录成功
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _checkLogin());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

  /// 同步 WebView Cookie → 原生 cookie 池；用 *_auth cookie 判定登录成功
  Future<void> _checkLogin() async {
    if (_checking || _done) return;
    _checking = true;
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      if (cookies.isEmpty) return;
      final hasAuth = cookies.any((c) => c.name.endsWith('_auth') && c.value.isNotEmpty);
      if (!hasAuth) return;
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
      _done = true;
      // 先落登录态，用户信息异步刷新（失败也不影响登录）
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