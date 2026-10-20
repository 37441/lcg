import 'package:flutter/material.dart';

import '../../core/utils/toast.dart';
import '../../data/repository/login_repository.dart';
import '../../theme/ui_tokens.dart';
import 'web_login_page.dart';

/// 登录页：表单收集账号/密码/安全提问，验证码在网页内「点击验证」完成
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _repo = LoginRepository.instance;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();

  LoginPageData? _pageData;
  var _loadingPage = true;
  var _selectedQuestionId = '0';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLoginPage();
  }

  Future<void> _fetchLoginPage() async {
    setState(() => _loadingPage = true);
    try {
      final data = await _repo.fetchLoginPage();
      if (!mounted) return;
      setState(() {
        _pageData = data;
        _loadingPage = false;
        _selectedQuestionId =
            data.questionOptions.isNotEmpty ? data.questionOptions.first.id : '0';
      });
    } catch (_) {
      setState(() {
        _loadingPage = false;
      });
    }
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final answer = _answerCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }
    final data = _pageData;
    if (data != null && data.hasSecurityQuestion && _selectedQuestionId != '0' && answer.isEmpty) {
      setState(() => _error = '请输入安全提问答案');
      return;
    }
    setState(() => _error = null);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WebLoginPage(
          username: username,
          password: password,
          questionId: _selectedQuestionId,
          answer: answer,
        ),
      ),
    );
    if (ok == true && mounted) {
      showToast(context, '登录成功');
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openWebLogin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WebLoginPage()),
    );
    if (ok == true && mounted) {
      showToast(context, '登录成功');
      Navigator.of(context).pop(true);
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
                      labelText: '账号',
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
                    if (_selectedQuestionId != '0') ...[
                      const SizedBox(height: UiTokens.spaceS),
                      TextField(
                        controller: _answerCtrl,
                        decoration: const InputDecoration(
                          labelText: '安全提问答案',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: UiTokens.spaceS),
                  // 验证码说明：52pojie 验证码为「点击验证」，在下一步网页内完成
                  Container(
                    padding: const EdgeInsets.all(UiTokens.spaceM),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(UiTokens.cornerXs),
                    ),
                    child: const Text(
                      '验证码：点击下方「登录」后，在网页中点击「点击验证」完成人机验证即可。',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A6D3B)),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: UiTokens.spaceS),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: UiTokens.fontTag, color: scheme.error),
                    ),
                  ],
                  const SizedBox(height: UiTokens.spaceM),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(UiTokens.sizeButton),
                    ),
                    child: const Text('登录'),
                  ),
                  const SizedBox(height: UiTokens.spaceS),
                  TextButton(
                    onPressed: _openWebLogin,
                    child: const Text('直接使用网页登录',
                        style: TextStyle(color: UiTokens.textLink)),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }
}