import 'package:flutter/material.dart';

import '../../widgets/floating_nav_bar.dart';
import '../discover/discover_page.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../message/message_page.dart';
import '../search/search_page.dart';

/// 主框架：底部导航 4 Tab（PageView 丝滑切换 + 页面状态保活）
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('吾爱破解'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final page in _pages) _KeepAlivePage(child: page),
        ],
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