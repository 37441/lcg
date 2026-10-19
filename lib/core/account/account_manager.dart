import 'package:flutter/foundation.dart';

import 'user_info.dart';

/// 账号状态 —— 对应原生 AccountManager.kt（LiveData → ChangeNotifier）
class AccountManager extends ChangeNotifier {
  AccountManager._();

  static final AccountManager instance = AccountManager._();

  bool _isLoggedIn = false;
  bool _isSignedToday = false;
  UserInfo _userInfo = UserInfo.defaultUserInfo();

  bool get isLoggedIn => _isLoggedIn;
  bool get isSignedToday => _isSignedToday;
  UserInfo get userInfo => _userInfo;

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  void setSignedToday(bool value) {
    _isSignedToday = value;
    notifyListeners();
  }

  void setUserInfo(UserInfo info) {
    _userInfo = info;
    notifyListeners();
  }

  void restore({required bool loggedIn, required UserInfo userInfo}) {
    _isLoggedIn = loggedIn;
    _userInfo = userInfo;
    notifyListeners();
  }

  Future<void> clearAll() async {
    _isLoggedIn = false;
    _isSignedToday = false;
    _userInfo = UserInfo.defaultUserInfo();
    notifyListeners();
  }
}