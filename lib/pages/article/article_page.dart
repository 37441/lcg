import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/account/account_manager.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/toast.dart';
import '../../data/models/article.dart';
import '../../data/repository/articles_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';
import '../webview/waf_challenge_page.dart';

/// 帖子详情页：滚动自动拼接下一页 + 底部回复栏
class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.url});

  final String url;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final _repo = ArticlesRepository.instance;
  final _scrollController = ScrollController();
  final _replyCtrl = TextEditingController();

  final _posts = <Post>[];
  String _title = '';
  String _nextPageUrl = '';
  String _formHash = '';
  String _replyFormAction = '';

  var _loading = true;
  var _loadingMore = false;
  var _sending = false;
  var _wafTried = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _posts.clear();
      _nextPageUrl = '';
    });
    try {
      final detail = await _repo.fetchArticleDetail(widget.url);
      if (!mounted) return;
      setState(() {
        _title = detail.title;
        _posts.addAll(detail.posts);
        _nextPageUrl = detail.nextPageUrl;
        _formHash = detail.formHash;
        _replyFormAction = detail.replyFormAction;
        _loading = false;
      });
    } on WafChallengeException catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      if (_wafTried) {
        setState(() => _error = '安全验证未通过，请重试');
        return;
      }
      _wafTried = true;
      final ok = await WafChallengePage.ensure(context, e.url);
      if (!mounted) return;
      if (ok) {
        await _load();
      } else {
        setState(() => _error = '安全验证未通过，请重试');
      }
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

  /// 自动加载并拼接下一页
  Future<void> _loadMore() async {
    if (_loadingMore || _nextPageUrl.isEmpty) return;
    _loadingMore = true;
    if (mounted) setState(() {});
    try {
      final detail = await _repo.fetchArticleDetail(_nextPageUrl, isFirstFetch: false);
      if (!mounted) return;
      setState(() {
        _posts.addAll(detail.posts);
        _nextPageUrl = detail.nextPageUrl;
        if (detail.formHash.isNotEmpty) _formHash = detail.formHash;
        if (detail.replyFormAction.isNotEmpty) _replyFormAction = detail.replyFormAction;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _sendReply() async {
    final message = _replyCtrl.text.trim();
    if (message.isEmpty) {
      showToast(context, '请输入回复内容');
      return;
    }
    if (!AccountManager.instance.isLoggedIn) {
      showToast(context, '请先登录后再回复');
      return;
    }
    if (_replyFormAction.isEmpty || _formHash.isEmpty) {
      showToast(context, '暂时无法回复（未获取到回复表单）');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final err = await _repo.replyPost(
      replyAction: _replyFormAction,
      formHash: _formHash,
      message: message,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (err == null) {
      _replyCtrl.clear();
      showToast(context, '回复成功');
      await _load();
    } else {
      showToast(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帖子详情')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    Expanded(child: _buildContent()),
                    _buildReplyBar(),
                  ],
                ),
    );
  }

  Widget _buildContent() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(UiTokens.spaceM),
      children: [
        Text(
          _title,
          style: TextStyle(
            fontSize: UiTokens.fontBody,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: UiTokens.spaceM),
        for (final post in _posts) _PostCard(post: post),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              _loadingMore
                  ? '加载中…'
                  : (_nextPageUrl.isEmpty ? '没有更多了' : '上滑加载更多'),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyBar() {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
                decoration: InputDecoration(
                  hintText: '回复帖子…',
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _sendReply,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
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