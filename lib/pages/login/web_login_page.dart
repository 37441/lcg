import 'dart:async';
import 'dart:convert';
import 'dart:io' show Cookie;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/account/user_data_repo.dart';
import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/cookie_store.dart';
import '../../core/utils/app_log.dart';
import '../../data/repository/login_repository.dart';

/// 内嵌网页登录（52pojie 验证码为「点击验证」，需真实网页环境）
/// - 自动填充账号密码 → 自动点击「点击验证」→ 自动提交登录（无感）
/// - 自动流程失败时回退手动：用户自行点验证并登录
/// - 登录成功判定：页面登录态 DOM（#um/.vwmy）或 cookie *_auth 出现即同步 Cookie 并自动返回
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
  var _manualHint = false;
  final _filled = <String>{};
  final _autoTried = <String>{};
  Timer? _timer;
  Timer? _hintTimer;

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

  static const _jsFill = '''
(function(un, pw, qid, ans){
  try {
    var u=document.querySelector('input[name="username"]'); if(u) u.value=un;
    var p=document.querySelector('input[name="password"]'); if(p) p.value=pw;
    var a=document.querySelector('input[name="answer"]'); if(a && ans) a.value=ans;
    var q=document.querySelector('select[name="questionid"]'); if(q) q.value=qid;
  } catch(e) {}
})''';

  static const _jsClickVerify = '''
(function(){
  try {
    var sels = ['#vseccode_cS input[type=checkbox]', '#vseccode_cS .verify',
      '[class*=verify] input[type=checkbox]', 'input[type=checkbox][name*=seccode]',
      '#nc_1_wrapper', '.sclogin_verify'];
    for (var i=0;i<sels.length;i++){ var el=document.querySelector(sels[i]); if(el){ el.click(); return 'clicked'; } }
    var all=document.querySelectorAll('div,span,label,button,a');
    for (var j=0;j<all.length;j++){
      var t=(all[j].innerText||'').trim();
      if(t==='点击验证' || t==='点击按钮进行验证'){ all[j].click(); return 'clicked-text'; }
    }
  } catch(e) {}
  return 'none';
})();
''';

  static const _jsSubmit = '''
(function(){
  try {
    var btn=document.querySelector('button[type=submit], input[type=submit], #login_btn, button[name=loginsubmit]');
    if(!btn){
      var bs=document.querySelectorAll('button,a,input');
      for(var k=0;k<bs.length;k++){
        var t=(bs[k].innerText||bs[k].value||'').trim();
        if(t==='登录'){ btn=bs[k]; break; }
      }
    }
    if(btn){ btn.click(); return 'clicked'; }
    var f=document.querySelector('form[action*=loginsubmit]');
    if(f){ f.submit(); return 'submitted'; }
  } catch(e) {}
  return 'none';
})();
''';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _checkLogin());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _fillForm(Uri? url) async {
    final controller = _controller;
    if (controller == null || widget.username == null || widget.password == null) return;
    final urlStr = url?.toString() ?? '';
    if (!urlStr.contains('action=login') || _filled.contains(urlStr)) return;
    _filled.add(urlStr);
    final js = '$_jsFill(${jsonEncode(widget.username)}, ${jsonEncode(widget.password)}, '
        '${jsonEncode(widget.questionId)}, ${jsonEncode(widget.answer)})';
    try {
      await controller.evaluateJavascript(source: js);
    } catch (_) {}
  }

  /// 自动点击验证 + 自动提交（无感登录；失败则交由用户手动完成）
  Future<void> _autoVerifyAndSubmit(Uri? url) async {
    final controller = _controller;
    if (controller == null || widget.username == null || widget.password == null) return;
    final urlStr = url?.toString() ?? '';
    if (!urlStr.contains('action=login') || _autoTried.contains(urlStr)) return;
    _autoTried.add(urlStr);
    try {
      await controller.evaluateJavascript(source: _jsClickVerify);
      await Future.delayed(const Duration(seconds: 3));
      await controller.evaluateJavascript(source: _jsSubmit);
      // 12 秒仍未成功 → 提示手动
      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && !_done) setState(() => _manualHint = true);
      });
    } catch (_) {}
  }

  Future<void> _checkLogin() async {
    if (_checking || _done) return;
    _checking = true;
    try {
      var logged = false;
      final controller = _controller;
      if (controller != null) {
        try {
          final r = await controller.evaluateJavascript(source: _jsLoggedCheck);
          if ((r?.toString() ?? '').contains('OK')) logged = true;
        } catch (_) {}
      }
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
      logD('login', '检测到登录成功，同步 ${cookies.length} 个 cookie');

      if (jarCookies.isNotEmpty) {
        try {
          await CookieStore.jar.saveFromResponse(
            Uri.parse(WebsiteConstants.serverBaseUrl),
            jarCookies,
          );
        } catch (_) {}
      }
      // 同时保存原始 Cookie 头，原生请求优先使用（避免域匹配问题）
      try {
        final header = cookies.map((c) => '${c.name}=${c.value}').join('; ');
        await CookieStore.setWebCookieHeader(header);
      } catch (_) {}
      _done = true;
      UserDataRepo.setLoggedIn(true);
      logD('login', '登录态已写入，自动返回');
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
            color: _manualHint ? const Color(0xFFFFEDD5) : const Color(0xFFFFF7E6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              _manualHint
                  ? '自动登录未完成，请手动点击「点击验证」并点「登录」。'
                  : '正在自动填写并完成验证，请稍候；如需手动操作，点击「点击验证」后登录即可。',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A6D3B)),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(WebsiteConstants.serverBaseUrl + WebsiteConstants.loginQuery),
              ),
              initialSettings: InAppWebViewSettings(userAgent: ApiClient.userAgent),
              onWebViewCreated: (controller) => _controller = controller,
              onLoadStop: (controller, url) async {
                _controller = controller;
                await _fillForm(url);
                await _autoVerifyAndSubmit(url);
                await _checkLogin();
              },
            ),
          ),
        ],
      ),
    );
  }
}