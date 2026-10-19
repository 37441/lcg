import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../data/models/misc_models.dart';
import '../../data/repository/search_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 搜索页（对应 LCGSearchActivity / BaiduSearchActivity）
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = SearchRepository.instance;
  final _ctrl = TextEditingController();
  List<LCGSearchResultItem> _items = [];
  var _loading = false;
  String? _engine; // 0=站内 1=百度

  @override
  void initState() {
    super.initState();
    _engine = AppConfig.defaultSearchEngine == AppConfig.searchEngineBaidu ? '百度' : '站内';
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final useBaidu = _engine == '百度';
      if (useBaidu) {
        final result = await _repo.searchBaidu(keyword);
        if (!mounted) return;
        setState(() {
          _items = result.baiduSearchResultList
              .map((r) => LCGSearchResultItem(
                    title: r.title,
                    content: r.contentAbstract,
                    url: r.url,
                  ))
              .toList();
          _loading = false;
        });
      } else {
        final result = await _repo.searchWuai(keyword);
        if (!mounted) return;
        setState(() {
          _items = result.searchResultList;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UiTokens.spaceM),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: '输入关键词',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(UiTokens.cornerXs),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: UiTokens.spaceS),
                DropdownButton<String>(
                  value: _engine,
                  items: const [
                    DropdownMenuItem(value: '站内', child: Text('站内')),
                    DropdownMenuItem(value: '百度', child: Text('百度')),
                  ],
                  onChanged: (v) => setState(() => _engine = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _items.isEmpty
                    ? const EmptyView(text: '输入关键词开始搜索')
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return ListTile(
                            title: Text(item.title,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              item.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: UiTokens.fontTag,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () => Navigator.pushNamed(context, '/article',
                                arguments: item.fullUrl),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}