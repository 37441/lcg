import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../data/models/article.dart';
import '../../data/repository/articles_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 文章详情页（对应 ArticleFragment）
class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.url});

  final String url;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final _repo = ArticlesRepository.instance;
  ArticleDetail? _detail;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.fetchArticleDetail(widget.url);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on BlockException catch (e) {
      setState(() {
        _error = e.message.isEmpty ? '抱歉，帖子已被删除或需要权限' : e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败：$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: const Text('帖子详情')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : detail == null
                  ? const EmptyView()
                  : _buildContent(detail),
    );
  }

  Widget _buildContent(ArticleDetail detail) {
    return ListView(
      padding: const EdgeInsets.all(UiTokens.spaceM),
      children: [
        Text(
          detail.title,
          style: TextStyle(
            fontSize: UiTokens.fontBody,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: UiTokens.spaceM),
        for (final post in detail.posts) _PostCard(post: post),
        if (detail.nextPageUrl.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticlePage(
                    url: 'https://www.52pojie.cn/${detail.nextPageUrl}',
                  ),
                ),
              );
            },
            child: const Text('下一页'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: UiTokens.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (post.avatar.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(UiTokens.cornerS),
                    child: CachedNetworkImage(
                      imageUrl: post.avatar,
                      width: UiTokens.sizeAvatar,
                      height: UiTokens.sizeAvatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.person),
                    ),
                  ),
                const SizedBox(width: UiTokens.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: TextStyle(
                          fontSize: UiTokens.fontBody,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        post.date,
                        style: TextStyle(
                          fontSize: UiTokens.fontTag,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UiTokens.spaceS),
            const Divider(height: 1),
            const SizedBox(height: UiTokens.spaceS),
            HtmlView(html: post.content),
          ],
        ),
      ),
    );
  }
}