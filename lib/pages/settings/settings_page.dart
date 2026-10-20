import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/account/account_manager.dart';
import '../../core/account/user_data_repo.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme_controller.dart';
import '../../core/network/cookie_store.dart';
import '../../core/utils/toast.dart';
import '../login/login_page.dart';
import 'diagnostics_page.dart';

/// 设置页（对应 SettingActivity）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final am = context.watch<AccountManager>();
    final tc = context.watch<ThemeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('『应用设置』')),
      body: ListView(
        children: [
          _Section(title: '外观'),
          // 主题色选择
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < ThemeController.presets.length; i++)
                  GestureDetector(
                    onTap: () => tc.setPreset(i),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: ThemeController.presets[i].primary,
                        shape: BoxShape.circle,
                        border: tc.presetIndex == i
                            ? Border.all(color: const Color(0xFF111111), width: 2)
                            : null,
                      ),
                      child: tc.presetIndex == i
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('主题模式'),
            trailing: DropdownButton<ThemeMode>(
              value: tc.mode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('深色/夜间')),
              ],
              onChanged: (v) {
                if (v != null) tc.setMode(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('字体大小'),
            trailing: DropdownButton<double>(
              value: tc.fontScale,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 0.9, child: Text('小')),
                DropdownMenuItem(value: 1.0, child: Text('标准')),
                DropdownMenuItem(value: 1.15, child: Text('大')),
                DropdownMenuItem(value: 1.25, child: Text('特大')),
              ],
              onChanged: (v) {
                if (v != null) tc.setFontScale(v);
              },
            ),
          ),
          _Section(title: '账号'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(am.isLoggedIn ? UserDataRepo.username : '登录'),
            trailing: am.isLoggedIn
                ? TextButton(
                    onPressed: _logout,
                    child: const Text('退出'),
                  )
                : const Icon(Icons.chevron_right),
            onTap: am.isLoggedIn
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event_available_outlined),
            title: const Text('开启自动签到'),
            value: AppConfig.autoSignEnable,
            onChanged: (v) => setState(() => AppConfig.autoSignEnable = v),
          ),
          _Section(title: '搜索'),
          SwitchListTile(
            secondary: const Icon(Icons.web_outlined),
            title: const Text('网页形式打开搜索结果'),
            value: AppConfig.searchResultShowInWebView,
            onChanged: (v) => setState(() => AppConfig.searchResultShowInWebView = v),
          ),
          _Section(title: '文章'),
          SwitchListTile(
            secondary: const Icon(Icons.web_outlined),
            title: const Text('网页形式打开文章'),
            value: AppConfig.articleShowInWebView,
            onChanged: (v) => setState(() => AppConfig.articleShowInWebView = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.star_outline),
            title: const Text('标题显示推荐标签'),
            value: AppConfig.articleShowRecommendFlag,
            onChanged: (v) => setState(() => AppConfig.articleShowRecommendFlag = v),
          ),
          _Section(title: '收藏'),
          SwitchListTile(
            secondary: const Icon(Icons.sync_outlined),
            title: const Text('同步收藏文章到网站'),
            subtitle: const Text('（默认仅收藏到本地）'),
            value: AppConfig.syncFavorites,
            onChanged: (v) => setState(() => AppConfig.syncFavorites = v),
          ),
          _Section(title: '应用'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: const Text('1.9.2'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('诊断日志'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosticsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await CookieStore.clearAll();
    await UserDataRepo.clearAll();
    if (mounted) {
      showToast(context, '本地信息已清除');
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}