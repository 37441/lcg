import 'package:flutter/material.dart';

import '../../data/models/discover.dart';
import '../../data/repository/rank_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 今日热榜页（原发现页排行榜）
class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
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
    setState(() => _loading = true);
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
    return Scaffold(
      backgroundColor: UiTokens.communityBg,
      appBar: AppBar(title: const Text('今日热榜')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
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
                      selectedColor: UiTokens.mintGreenLight,
                      labelStyle: TextStyle(
                        color: _type == type ? UiTokens.mintGreen : UiTokens.textGray,
                        fontWeight: _type == type ? FontWeight.w600 : FontWeight.normal,
                      ),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: UiTokens.spaceM, vertical: 4),
                            color: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: Text(
                                '${item.index}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: i < 3 ? UiTokens.mintGreen : UiTokens.textGray,
                                ),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, color: UiTokens.textDark),
                              ),
                              subtitle: Text(
                                '${item.forum} · ${item.authorName}',
                                style:
                                    const TextStyle(fontSize: 12, color: UiTokens.textGray),
                              ),
                              trailing: Text(
                                '${_typeLabel(item.type)} ${item.num}',
                                style: const TextStyle(fontSize: 12, color: UiTokens.textGray),
                              ),
                              onTap: () => Navigator.pushNamed(context, '/article',
                                  arguments: item.url.startsWith('http')
                                      ? item.url
                                      : 'https://www.52pojie.cn/${item.url}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
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