import 'package:flutter/material.dart';

import '../theme/ui_tokens.dart';

/// 底部导航：药丸式选中态（选中 Tab 包裹浅薄荷绿胶囊，未选中仅灰色图标文字）
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home, '首页'),
    (Icons.explore_outlined, Icons.explore, '社区'),
    (Icons.notifications_outlined, Icons.notifications, '消息'),
    (Icons.person_outline, Icons.person, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(UiTokens.spaceM, 0, UiTokens.spaceM, 10),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? UiTokens.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onTap(i),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentIndex == i
                            ? scheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            currentIndex == i ? _items[i].$2 : _items[i].$1,
                            size: 20,
                            color: currentIndex == i
                                ? scheme.primary
                                : UiTokens.tabUnselected,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$3,
                            style: TextStyle(
                              fontSize: UiTokens.fontTag,
                              fontWeight: currentIndex == i
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: currentIndex == i
                                  ? scheme.primary
                                  : UiTokens.tabUnselected,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}