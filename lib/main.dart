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
  _autoSignInIfNeeded();
  runApp(const LcgApp());
}

/// 每天第一次打开自动签到（对应原生 SignInWorker，成功后记录日期避免重复）
void _autoSignInIfNeeded() {
  if (!AccountManager.instance.isLoggedIn || !AppConfig.autoSignEnable) return;
  final now = DateTime.now();
  final today =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  if (AppConfig.lastSignInDate == today) return;
  Future.delayed(const Duration(seconds: 2), () async {
    final ok = await SignInService.instance.trySignIn();
    if (ok) {
      AppConfig.lastSignInDate = today;
    }
  });
}