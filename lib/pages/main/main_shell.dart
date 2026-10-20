import 'package:flutter/material.dart';

import '../../theme/ui_tokens.dart';
import '../../widgets/floating_nav_bar.dart';
import '../discover/discover_page.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../message/message_page.dart';
import '../search/search_page.dart';

/// 主框架：紧凑顶栏 + 底部胶囊导航（PageView 平滑切换 + 页面状态保活）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _controller = PageController(initialPage: 0);

  static const _pages = [
    HomePage(),
    DiscoverPage(),
    MessagePage(),
    MePage(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 紧凑顶栏（取代 AppBar，减小顶部占位）
            Padding(
              padding: const EdgeInsets.fromLTRB(UiTokens.spaceM, 6, UiTokens.spaceXs, 2),
              child: Row(
                children: [
                  Text(
                    '吾爱破解',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE6E6E6) : UiTokens.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: UiTokens.mintGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '52pojie.cn',
                      style: TextStyle(fontSize: 11, color: UiTokens.mintGreen),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    icon: Icon(Icons.search,
                        color: isDark ? const Color(0xFFE6E6E6) : UiTokens.textDark),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final page in _pages) _KeepAlivePage(child: page),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: _switchTo,
      ),
    );
  }
}

/// 保持各 Tab 页面状态（滚动位置等）不被销毁
class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}