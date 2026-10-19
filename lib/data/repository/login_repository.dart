import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../core/account/user_data_repo.dart';
import '../../core/account/user_info.dart';
import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/cookie_store.dart';
import '../../core/utils/md5.dart';
import '../parser/doc_parser.dart';

/// 登录页解析结果（对应原生 LoginPageData）
class LoginPageData {
  LoginPageData({
    required this.formHash,
    required this.loginHash,
    this.captchaUrl,
    this.captchaHash,
    this.questionOptions = const [],
  });

  final String formHash;
  final String loginHash;
  final String? captchaUrl;
  final String? captchaHash;
  final List<LoginQuestionOption> questionOptions;

  bool get hasCaptcha {
    final url = captchaUrl;
    return url != null && url.isNotEmpty;
  }

  bool get hasSecurityQuestion => questionOptions.length > 1;
}

class LoginQuestionOption {
  LoginQuestionOption({required this.id, required this.text});

  final String id;
  final String text;
}

sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess();
}

class LoginFailed extends LoginResult {
  const LoginFailed(this.message);
  final String message;
}

/// 登录仓库 —— 对应原生 LoginViewModel.kt + UserInfoRepo.requestUserInfo
class LoginRepository {
  LoginRepository._();

  static final LoginRepository instance = LoginRepository._();

  final _api = ApiClient.instance;

  /// 拉取登录页：formhash/loginhash/验证码/安全提问
  Future<LoginPageData> fetchLoginPage() async {
    final doc = await _api.getWithQuery(WebsiteConstants.loginQuery);
    ApiClient.instance.formHash = DocParser.extractFormHash(doc.documentElement!.outerHtml);
    return _parseLoginPage(doc);
  }

  /// 登录：Discuz POST，密码 md5(md5(明文)+saltkey)
  Future<LoginResult> doLogin({
    required String username,
    required String password,
    String questionId = '0',
    String answer = '',
    String captcha = '',
  }) async {
    try {
      final page = await fetchLoginPage();
      _syncFormHash(page.formHash);

      final saltKey = await CookieStore.valueOf('saltkey') ?? '';
      final form = <String, String>{
        'username': username,
        'password': md5Hex(md5Hex(password) + saltKey),
        'questionid': questionId,
        'answer': answer,
        'formhash': page.formHash,
        'referer': WebsiteConstants.serverBaseUrl,
        'cookietime': '2592000',
      };
      if (page.hasCaptcha) {
        form['seccodeverify'] = captcha;
      }
      final captchaHash = page.captchaHash;
      if (captchaHash != null && captchaHash.isNotEmpty) {
        form['seccodehash'] = captchaHash;
      }

      final loginUrl = _buildLoginUrl(page);
      final resp = await _api.postForm(loginUrl, form);
      final body = resp.data ?? '';
      final doc = html_parser.parse(body);

      if (doc.querySelector('div.avt') != null || body.contains('欢迎您回来')) {
        return _handleSuccess();
      }
      final err = _extractError(doc);
      if (err.isNotEmpty) {
        return LoginFailed(err);
      }
      // 无法判定时用个人页验证
      try {
        final info = await _requestUserInfo();
        if (info.isValid) {
          return _handleSuccess();
        }
      } catch (_) {}
      return const LoginFailed('登录失败，请重试');
    } catch (e) {
      return LoginFailed('登录失败：$e');
    }
  }

  /// 网页登录兜底后：用个人页验证并回写登录态
  Future<LoginResult> verifyLoggedInAfterWebLogin() async {
    try {
      final info = await _requestUserInfo();
      if (info.isValid) {
        return _handleSuccess();
      }
      return const LoginFailed('尚未登录');
    } catch (e) {
      return LoginFailed('验证登录失败：$e');
    }
  }

  Future<LoginResult> _handleSuccess() async {
    UserDataRepo.setLoggedIn(true);
    try {
      final info = await _requestUserInfo();
      UserDataRepo.updateUserInfo(info);
    } catch (_) {}
    return const LoginSuccess();
  }

  /// 拉取用户信息（对应 UserInfoRepo.requestUserInfo）
  Future<UserInfo> _requestUserInfo() async {
    final doc = await _api.getWithQuery(WebsiteConstants.profileQuery);
    if (ApiClient.instance.formHash == null) {
      _syncFormHash(DocParser.extractFormHash(doc.documentElement!.outerHtml) ?? '');
    }
    return DocParser.parseUserInfo(doc.documentElement!.outerHtml);
  }

  String _buildLoginUrl(LoginPageData page) {
    var url = '${WebsiteConstants.serverBaseUrl}member.php?mod=logging'
        '&action=login&loginsubmit=yes';
    if (page.loginHash.isNotEmpty) url += '&loginhash=${page.loginHash}';
    if (page.formHash.isNotEmpty) url += '&formhash=${page.formHash}';
    return url;
  }

  String _extractError(dom.Document doc) {
    final t = doc.getElementById('messagetext')?.text ?? '';
    if (t.isNotEmpty) return t;
    final show = doc.querySelector('div.showmessage')?.text ?? '';
    if (show.isNotEmpty) return show;
    return '';
  }

  LoginPageData _parseLoginPage(dom.Document doc) {
    final form = doc.querySelector('form[action*="action=login"]');
    var formHash = form?.querySelector('input[name="formhash"]')?.attributes['value'] ?? '';
    if (formHash.isEmpty) {
      formHash = DocParser.extractFormHash(doc.documentElement!.outerHtml) ?? '';
    }
    var loginHash = '';
    final action = form?.attributes['action'] ?? '';
    final m = RegExp(r'loginhash=([a-zA-Z0-9]+)').firstMatch(action);
    if (m != null) loginHash = m.group(1)!;

    String? captchaUrl;
    String? captchaHash;
    final img = doc.getElementById('vseccode_cS')?.querySelector('img[width="130"]');
    final src = img?.attributes['src'] ?? '';
    if (src.isNotEmpty) {
      final fullUrl = src.startsWith('http') ? src : WebsiteConstants.serverBaseUrl + src;
      captchaUrl = fullUrl;
      final hm = RegExp(r'[?&]idhash=([a-zA-Z0-9]+)').firstMatch(fullUrl);
      if (hm != null) captchaHash = hm.group(1);
    }

    final options = <LoginQuestionOption>[];
    for (final option in doc.querySelectorAll('select[name="questionid"] option')) {
      final id = option.attributes['value'] ?? '';
      if (id.isNotEmpty) {
        options.add(LoginQuestionOption(id: id, text: option.text.trim()));
      }
    }
    return LoginPageData(
      formHash: formHash,
      loginHash: loginHash,
      captchaUrl: captchaUrl,
      captchaHash: captchaHash,
      questionOptions: options,
    );
  }

  void _syncFormHash(String hash) {
    if (hash.isNotEmpty) {
      ApiClient.instance.formHash = hash;
    }
  }
}
