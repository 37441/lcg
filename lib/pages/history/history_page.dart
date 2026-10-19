import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../data/models/article.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 阅读记录页（对应 HistoryArticlesFragment）
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _repo = HistoryRepository.instance;
  List<ArticleEntity> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        title: const Text('阅读记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _items.isEmpty
                ? null
                : () async {
                    await _repo.clear();
                    _load();
                  },
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(text: '看过的文章才有记录哦')
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: UiTokens.spaceM, vertical: 4),
                      child: ListTile(
                        title: Text(item.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          item.author,
                          style: const TextStyle(fontSize: UiTokens.fontTag),
                        ),
                        onTap: () => Navigator.pushNamed(context, '/article',
                            arguments: item.fullUrl),
                      ),
                    );
                  },
                ),
    );
  }
}