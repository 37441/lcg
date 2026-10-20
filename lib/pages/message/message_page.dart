import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/website_constants.dart';
import '../../data/repository/message_repository.dart';
import '../../theme/ui_tokens.dart';
import '../../widgets/common_views.dart';

/// 消息页：通知列表（对应 MessageFragment/NotificationFragment）
class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _repo = MessageRepository.instance;
  List<NoticeItem> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final result = await _repo.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_items.isEmpty) return const EmptyView(text: '目前没有通知');
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: UiTokens.spaceM, vertical: 4),
            child: ListTile(
              leading: item.avatar.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(UiTokens.cornerS),
                      child: CachedNetworkImage(
                        imageUrl: item.avatar,
                        httpHeaders: const {
                          'Referer': WebsiteConstants.serverBaseUrl,
                          'User-Agent': WebsiteConstants.desktopUserAgent,
                        },
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person),
                      ),
                    )
                  : const Icon(Icons.notifications_none),
              title: HtmlView(html: item.content),
              subtitle: Text(
                item.dateTime,
                style: TextStyle(
                  fontSize: UiTokens.fontTag,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 完整通知列表页（对应 NotificationListFragment）
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全部通知')),
      body: const MessagePage(),
    );
  }
}