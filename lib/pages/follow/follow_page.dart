import 'package:flutter/material.dart';

import '../../data/models/misc_models.dart';
import '../../data/repository/follow_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 关注页：广播动态 + 收听列表（对应 FollowFragment）
class FollowPage extends StatefulWidget {
  const FollowPage({super.key});

  @override
  State<FollowPage> createState() => _FollowPageState();
}

class _FollowPageState extends State<FollowPage> {
  final _repo = FollowRepository.instance;
  List<FeedInfo> _feeds = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final feeds = await _repo.fetchFeed();
      if (!mounted) return;
      setState(() {
        _feeds = feeds;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的收听')),
      body: _loading
          ? const LoadingView()
          : _feeds.isEmpty
              ? const EmptyView(text: '暂无广播动态')
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    itemCount: _feeds.length,
                    itemBuilder: (context, i) {
                      final feed = _feeds[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: UiTokens.spaceM, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(UiTokens.spaceM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      feed.username,
                                      style: TextStyle(
                                        fontSize: UiTokens.fontAux,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    feed.dateTime,
                                    style: TextStyle(
                                      fontSize: UiTokens.fontTag,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (feed.title.isNotEmpty) ...[
                                const SizedBox(height: UiTokens.spaceS),
                                Text(
                                  feed.title,
                                  style: TextStyle(
                                    fontSize: UiTokens.fontBody,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                              if (feed.content.isNotEmpty) ...[
                                const SizedBox(height: UiTokens.spaceS),
                                Text(
                                  _plainText(feed.content),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: UiTokens.fontAux,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (feed.forum.isNotEmpty) ...[
                                const SizedBox(height: UiTokens.spaceS),
                                Text(
                                  feed.forum,
                                  style: TextStyle(
                                    fontSize: UiTokens.fontTag,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _plainText(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .trim();
}