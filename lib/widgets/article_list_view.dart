import 'package:flutter/material.dart';

import '../data/models/article.dart';
import '../data/repository/articles_repository.dart';
import 'article_card.dart';
import 'common_views.dart';

/// 文章分页列表（首页/板块共用）
class ArticleListView extends StatefulWidget {
  const ArticleListView({super.key, required this.query});

  /// 相对路径 query（板块页直接传，首页传 view 参数由内部拼 base）
  final String query;

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> {
  final _repo = ArticlesRepository.instance;
  final _scrollController = ScrollController();
  final _items = <Article>[];
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  var _error = false;
  var _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      _loadMore();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final list = await _repo.fetchForumArticles('${widget.query}&page=$_page');
      setState(() {
        _items.addAll(list);
        _hasMore = list.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    _page++;
    try {
      final list = await _repo.fetchForumArticles('${widget.query}&page=$_page');
      setState(() {
        _items.addAll(list);
        _hasMore = list.isNotEmpty;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _page--;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error) return ErrorView(onRetry: _fetch);
    if (_items.isEmpty) return const EmptyView();
    return RefreshIndicator(
      onRefresh: () async {
        _items.clear();
        _page = 1;
        await _fetch();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  _loadingMore
                      ? '加载中…'
                      : (_hasMore ? '上拉加载更多' : '没有更多了'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          final article = _items[index];
          return ArticleCard(
            article: article,
            onTap: () => _openArticle(context, article),
          );
        },
      ),
    );
  }

  void _openArticle(BuildContext context, Article article) {
    Navigator.pushNamed(context, '/article', arguments: article.fullUrl);
  }
}
