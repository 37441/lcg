import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/account/account_manager.dart';
import '../../core/config/app_config.dart';
import '../../core/config/website_constants.dart';
import '../about/about_page.dart';
import '../discover/discover_page.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../message/message_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import '../webview/webview_page.dart';

/// 主框架：底部导航 4 Tab + 抽屉（对应 MainActivity）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [
    HomePage(),
    DiscoverPage(),
    MessagePage(),
    MePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('吾爱破解'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: '发现'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<AccountManager>(
        builder: (context, am, _) => ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    am.isLoggedIn ? (am.userInfo.userName ?? '') : '未登录',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (am.isLoggedIn && am.userInfo.groupInfo != null)
                    Text(
                      am.userInfo.groupInfo!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('『应用设置』'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('『关于应用』'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.web_outlined),
              title: const Text('『吾爱网页版』'),
              onTap: () {
                Navigator.pop(context);
                WebViewPage.open(context, WebsiteConstants.serverBaseUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer_outlined),
              title: const Text('『JRS看球』'),
              onTap: () {
                Navigator.pop(context);
                WebViewPage.open(context, AppConfig.jrsUrl);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
  }
}
