import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../data/models/article.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 收藏页：本地收藏（对应 FavoriteArticlesFragment）
class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final _repo = FavoriteLocalRepository.instance;
  List<ArticleEntity> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _items.isEmpty
                ? null
                : () async {
                    await _repo.clearAll();
                    _load();
                  },
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(text: '收藏夹目前是空的。')
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: UiTokens.spaceM, vertical: 4),
                      child: ListTile(
                        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          _relTime(item.timestamp),
                          style: const TextStyle(fontSize: UiTokens.fontTag),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/article',
                              arguments: item.fullUrl);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _relTime(int ts) {
    if (ts <= 0) return '';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${diff.inDays}天前';
  }
}
