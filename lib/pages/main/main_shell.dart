import 'package:flutter/material.dart';

import '../../widgets/floating_nav_bar.dart';
import '../discover/discover_page.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../message/message_page.dart';
import '../search/search_page.dart';

/// 主框架：悬浮胶囊底部导航 4 Tab（对应 MainActivity）
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}