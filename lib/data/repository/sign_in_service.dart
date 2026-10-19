import '../../core/config/app_config.dart';
import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';

/// 自动签到 —— 对应原生 SignInWorker.kt（启动时补签一次）
class SignInService {
  SignInService._();

  static final SignInService instance = SignInService._();

  static const _taskApplied = '已申请';

  /// 先 apply 任务，若返回「已申请」则 draw 领取奖励
  Future<bool> trySignIn() async {
    if (!AppConfig.autoSignEnable) return false;
    try {
      final applyDoc = await ApiClient.instance.getUrl(WebsiteConstants.signInApplyUrl);
      final alert = applyDoc.querySelector('.alert_info p')?.text ?? '';
      if (!alert.contains(_taskApplied)) return false;
      final drawDoc = await ApiClient.instance.getUrl(WebsiteConstants.signInDrawUrl);
      drawDoc.querySelector('.alert_info p')?.text;
      return true;
    } catch (_) {
      return false;
    }
  }
}