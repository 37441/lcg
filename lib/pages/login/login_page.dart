import 'dart:io' show Cookie;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide Cookie;

import '../../core/config/website_constants.dart';
import '../../core/network/cookie_store.dart';
import '../../core/utils/toast.dart';
import '../../data/repository/login_repository.dart';
import '../../theme/ui_tokens.dart';

/// 自定义表单登录页（对应 LoginDialog）
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _repo = LoginRepository.instance;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  LoginPageData? _pageData;
  var _loadingPage = true;
  var _submitting = false;
  var _selectedQuestionId = '0';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLoginPage();
  }

  Future<void> _fetchLoginPage() async {
    setState(() {
      _loadingPage = true;
    });
    try {
      final data = await _repo.fetchLoginPage();
      if (!mounted) return;
      setState(() {
        _pageData = data;
        _loadingPage = false;
        _selectedQuestionId = data.questionOptions.isNotEmpty
            ? data.questionOptions.first.id
            : '0';
      });
    } catch (e) {
      setState(() {
        _loadingPage = false;
        _error = '加载登录页失败，请检查网络后重试';
      });
    }
  }

  Future<void> _submit() async {
    final data = _pageData;
    if (data == null || _submitting) return;
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final answer = _answerCtrl.text.trim();
    final captcha = _captchaCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    // 选了具体安全提问才需要答案；「未设置请忽略」(id=0) 是合法选项
    if (data.hasSecurityQuestion && _selectedQuestionId != '0' && answer.isEmpty) {
      setState(() => _error = '请输入安全提问答案');
      return;
    }
    if (data.hasCaptcha && captcha.isEmpty) {
      setState(() => _error = '请输入验证码');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _repo.doLogin(
        username: username,
        password: password,
        questionId: _selectedQuestionId,
        answer: answer,
        captcha: captcha,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (result is LoginSuccess) {
        showToast(context, '登录成功');
        Navigator.of(context).pop(true);
      } else if (result is LoginFailed) {
        setState(() => _error = result.message);
        _fetchLoginPage(); // 刷新验证码/formhash
      }
    } catch (e) {
      // 网络/解析异常不能卡死在“登录中”
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '登录失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = _pageData;
    return Scaffold(
      appBar: AppBar(title: const Text('登录吾爱破解')),
      body: _loadingPage
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(UiTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: UiTokens.spaceS),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (data != null && data.hasSecurityQuestion) ...[
                    const SizedBox(height: UiTokens.spaceS),
                    DropdownButtonFormField<String>(
                      value: _selectedQuestionId,
                      items: [
                        for (var i = 0; i < data.questionOptions.length; i++)
                          DropdownMenuItem(
                            value: data.questionOptions[i].id,
                            child: Text(data.questionOptions[i].text),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedQuestionId = v ?? '0'),
                      decoration: const InputDecoration(
                        labelText: '安全提问',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    // 选择「未设置请忽略」时无需填写答案
                    if (_selectedQuestionId != '0') ...[const SizedBox(height: UiTokens.spaceS),
                      TextField(
                        controller: _answerCtrl,
                        decoration: const InputDecoration(
                          labelText: '安全提问答案',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                  if (data != null && data.hasCaptcha) ...[
                    const SizedBox(height: UiTokens.spaceS),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _captchaCtrl,
                            decoration: const InputDecoration(
                              labelText: '验证码',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: UiTokens.spaceS),
                        InkWell(
                          onTap: _fetchLoginPage,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(UiTokens.cornerXs),
                            child: CachedNetworkImage(
                              imageUrl: data.captchaUrl!,
                              height: 48,
                              width: 120,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.refresh),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: UiTokens.spaceS),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: UiTokens.fontTag,
                        color: scheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: UiTokens.spaceM),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(UiTokens.sizeButton),
                    ),
                    child: Text(_submitting ? '登录中…' : '登录'),
                  ),
                  const SizedBox(height: UiTokens.spaceS),
                  TextButton(
                    onPressed: () => _openWebLogin(),
                    child: const Text('遇到问题？使用网页登录',
                        style: TextStyle(color: UiTokens.textLink)),
                  ),
                ],
              ),
            ),
    );
  }

  void _openWebLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebLoginPage(
          onLoggedIn: () async {
            final result = await _repo.verifyLoggedInAfterWebLogin();
            if (result is LoginSuccess && mounted) {
              showToast(context, '登录成功');
              Navigator.of(context).pop(true);
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _captchaCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }
}

/// 网页登录兜底（对应 WebViewActivity.openLoginPage）
class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key, this.onLoggedIn});

  final VoidCallback? onLoggedIn;

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  var _syncing = false;
  var _done = false;

  /// 把 WebView 的 Cookie 同步到 dio 的 cookie 池（含 saltkey），否则后续原生请求仍是未登录
  Future<void> _syncCookiesAndNotify() async {
    if (_syncing || _done) return;
    _syncing = true;
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri(WebsiteConstants.serverBaseUrl));
      if (cookies.isNotEmpty) {
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
      }
      _done = true;
      widget.onLoggedIn?.call();
    } catch (_) {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网页登录')),
      body: InAppWebView(
        initialUrlRequest:
            URLRequest(url: WebUri(WebsiteConstants.serverBaseUrl + WebsiteConstants.loginQuery)),
        onLoadStop: (controller, url) async {
          // 登录成功后会跳转到论坛页（页面包含 div.avt）
          try {
            final count = await controller.evaluateJavascript(
                source: "document.querySelectorAll('div.avt').length");
            final s = count?.toString() ?? '0';
            if (s.isNotEmpty && s != '0') {
              await _syncCookiesAndNotify();
            }
          } catch (_) {}
        },
      ),
    );
  }
}