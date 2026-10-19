import 'package:flutter/material.dart';

import '../../core/config/website_constants.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/article_list_view.dart';

/// 首页：5 个分类 Tab（对应 RecommendFragment）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _tabs = [
    ('人气热门', 'hot'),
    ('技术分享', 'tech'),
    ('精华采撷', 'digest'),
    ('新鲜出炉', 'newthread'),
    ('求助新帖', 'help'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(
                fontSize: UiTokens.fontAux, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: UiTokens.fontAux),
            tabs: [for (final (title, _) in _tabs) Tab(text: title)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final (_, param) in _tabs)
                  ArticleListView(query: '${WebsiteConstants.forumBaseQuery}$param'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
