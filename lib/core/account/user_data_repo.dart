import 'package:shared_preferences/shared_preferences.dart';

import 'account_manager.dart';
import 'user_info.dart';

/// 用户数据持久化 —— 对应原生 UserDataRepo.kt
class UserDataRepo {
  UserDataRepo._();

  static const _kAvatar = 'sp_key_user_avatar';
  static const _kGroup = 'sp_key_user_group';
  static const _kCoin = 'sp_key_user_coin';
  static const _kCredit = 'sp_key_user_credit';
  static const _kEnthusiastic = 'sp_key_user_enthusiastic';
  static const _kAnswerRate = 'sp_key_user_answer_rate';
  static const _kName = 'sp_key_user_name';
  static const _kSignInState = 'sp_key_sign_in_state';
  static const _kLoggedIn = 'sp_key_logged_in';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final loggedIn = _prefs?.getBool(_kLoggedIn) ?? false;
    AccountManager.instance.restore(
      loggedIn: loggedIn,
      userInfo: _readUserInfo(),
    );
  }

  static bool get isLoggedIn => AccountManager.instance.isLoggedIn;

  static String get username => _prefs?.getString(_kName) ?? '';

  static String get avatar => _prefs?.getString(_kAvatar) ?? '';

  static UserInfo _readUserInfo() => UserInfo(
        userName: _prefs?.getString(_kName),
        groupInfo: _prefs?.getString(_kGroup),
        avatarUrl: _prefs?.getString(_kAvatar),
        wuaiCoin: _prefs?.getString(_kCoin),
        credit: _prefs?.getString(_kCredit),
        answerRate: _prefs?.getString(_kAnswerRate),
        enthusiasticValue: _prefs?.getString(_kEnthusiastic),
        signInStateUrl: _prefs?.getString(_kSignInState),
      );

  /// 登录成功后写入用户信息（对应 updateUserInfo）
  static void updateUserInfo(UserInfo info) {
    final p = _prefs;
    if (p == null) return;
    p.setString(_kName, info.userName ?? '');
    p.setString(_kAvatar, info.avatarUrl ?? '');
    p.setString(_kCoin, info.wuaiCoin ?? '');
    p.setString(_kCredit, info.credit ?? '');
    p.setString(_kGroup, info.groupInfo ?? '');
    p.setString(_kEnthusiastic, info.enthusiasticValue ?? '');
    p.setString(_kAnswerRate, info.answerRate ?? '');
    p.setString(_kSignInState, info.signInStateUrl ?? '');
    AccountManager.instance.setUserInfo(info);
  }

  static void setLoggedIn(bool value) {
    _prefs?.setBool(_kLoggedIn, value);
    AccountManager.instance.setLoggedIn(value);
  }

  static void setSignInState(String value) {
    _prefs?.setString(_kSignInState, value);
    AccountManager.instance.setSignedToday(value.isNotEmpty);
  }

  /// 退出登录：清除 cookie 与本地用户数据
  static Future<void> clearAll() async {
    await AccountManager.instance.clearAll();
    final p = _prefs;
    if (p == null) return;
    await p.remove(_kLoggedIn);
    await p.remove(_kName);
    await p.remove(_kAvatar);
    await p.remove(_kCoin);
    await p.remove(_kCredit);
    await p.remove(_kGroup);
    await p.remove(_kEnthusiastic);
    await p.remove(_kAnswerRate);
    await p.remove(_kSignInState);
  }
}