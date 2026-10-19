import 'package:flutter/material.dart';

import 'app.dart';
import 'core/account/account_manager.dart';
import 'core/account/user_data_repo.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'data/repository/sign_in_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  await AppConfig.init();
  await UserDataRepo.init();
  _trySignInOnLaunch();
  runApp(const LcgApp());
}

/// 启动后延迟补签（对应原生 LCGApp.trySignIn）
void _trySignInOnLaunch() {
  if (!AccountManager.instance.isLoggedIn) return;
  Future.delayed(const Duration(seconds: 2), () {
    SignInService.instance.trySignIn();
  });
}