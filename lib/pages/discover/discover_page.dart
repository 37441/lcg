import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/account/account_manager.dart';
import '../../core/config/website_constants.dart';
import '../../data/models/discover.dart';
import '../../data/repository/rank_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/article_list_view.dart';
import '../../widgets/common_views.dart';

/// 发现页：论坛板块导航 + 排行榜（对应 DiscoverFragment）
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: UiTokens.spaceS),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: '板块导航'),
              Tab(text: '排行榜'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ForumNavTab(),
                const _RankTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumNavTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AccountManager>().isLoggedIn;
    final common = <({String title, String url})>[
      (title: '移动安全', url: WebsiteConstants.mobSecurityQuery),
      (title: '精品软件', url: WebsiteConstants.softwareQuery),
      (title: '原创发布', url: WebsiteConstants.originalReleaseQuery),
      if (loggedIn) ...[
        (title: '水漫金山', url: WebsiteConstants.freeChatQuery),
        (title: '福利经验', url: WebsiteConstants.welfareQuery),
      ],
    ];
    final more = <({String title, String url})>[
      (title: '编程语言', url: WebsiteConstants.programLanguageQuery),
      (title: '动画发布', url: WebsiteConstants.animationReleaseQuery),
      (title: '逆向资源', url: WebsiteConstants.reverseResourceQuery),
      (title: '悬赏问答', url: WebsiteConstants.qaQuery),
      if (loggedIn) ...[
        (title: '病毒分析', url: WebsiteConstants.virusAnalysisQuery),
        (title: '病毒救援', url: WebsiteConstants.virusRescueQuery),
        (title: '病毒样本', url: WebsiteConstants.virusSampleQuery),
      ],
    ];

    return ListView(
      padding: const EdgeInsets.all(UiTokens.spaceM),
      children: [
        Text(
          '常用板块导航',
          style: TextStyle(
            fontSize: UiTokens.fontAux,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: UiTokens.spaceS),
        _ForumGrid(items: common),
        const SizedBox(height: UiTokens.spaceL),
        Text(
          '更多板块',
          style: TextStyle(
            fontSize: UiTokens.fontAux,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: UiTokens.spaceS),
        _ForumGrid(items: more),
      ],
    );
  }
}

class _ForumGrid extends StatelessWidget {
  const _ForumGrid({required this.items});

  final List<({String title, String url})> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(UiTokens.cornerS),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ForumArticlesPage(
                    title: item.title,
                    query: item.url,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.forum_outlined,
                      color: scheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(height: UiTokens.spaceS),
                Text(
                  item.title,
                  style: TextStyle(
                      fontSize: UiTokens.fontTag, color: scheme.onSurface),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ForumArticlesPage extends StatelessWidget {
  const _ForumArticlesPage({required this.title, required this.query});

  final String title;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ArticleListView(query: query),
    );
  }
}

class _RankTab extends StatefulWidget {
  const _RankTab();

  @override
  State<_RankTab> createState() => _RankTabState();
}

class _RankTabState extends State<_RankTab> {
  final _repo = RankRepository.instance;
  RankListModel? _model;
  var _loading = true;
  var _type = RankType.view;

  static const _types = [
    (RankType.view, '查看'),
    (RankType.reply, '回复'),
    (RankType.heat, '热度'),
    (RankType.favorite, '收藏'),
    (RankType.share, '分享'),
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
    });
    try {
      final model = await _repo.fetchRank(_type, DateType.today);
      if (!mounted) return;
      setState(() {
        _model = model;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: UiTokens.spaceM),
            children: [
              for (final (type, label) in _types)
                Padding(
                  padding: const EdgeInsets.only(right: UiTokens.spaceS),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _type == type,
                    onSelected: (_) {
                      setState(() => _type = type);
                      _fetch();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : (model == null || model.list.isEmpty)
                  ? const EmptyView()
                  : ListView.builder(
                      itemCount: model.list.length,
                      itemBuilder: (context, i) {
                        final item = model.list[i];
                        return ListTile(
                          leading: Text(
                            '${item.index}',
                            style: TextStyle(
                              fontSize: UiTokens.fontBody,
                              fontWeight: FontWeight.bold,
                              color: i < 3
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${item.forum} · ${item.authorName}'),
                          trailing: Text(
                            '${_typeLabel(item.type)} ${item.num}',
                            style: const TextStyle(fontSize: UiTokens.fontTag),
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/article',
                                arguments: item.url.startsWith('http')
                                    ? item.url
                                    : 'https://www.52pojie.cn/${item.url}');
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _typeLabel(RankType t) => switch (t) {
        RankType.view => '查看',
        RankType.reply => '回复',
        RankType.heat => '热度',
        RankType.favorite => '收藏',
        RankType.share => '分享',
      };
}