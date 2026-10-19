import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';

/// 通知条目
class NoticeItem {
  NoticeItem({required this.avatar, required this.content, required this.dateTime});

  final String avatar;
  final String content;
  final String dateTime;
}

/// 消息仓库 —— 对应原生 NotificationViewModel.kt
class MessageRepository {
  MessageRepository._();

  static final MessageRepository instance = MessageRepository._();

  Future<({List<NoticeItem> items, String nextPageUrl})> fetchNotifications(
      {String query = WebsiteConstants.notificationHomeQuery}) async {
    final doc = await ApiClient.instance.getWithQuery(query);
    final items = <NoticeItem>[];
    for (final dl in doc.querySelectorAll('dl.cl')) {
      try {
        final ntc = dl.querySelector('dd.ntc_body');
        if (ntc == null) continue;
        // 站内链接加 lcg: 前缀（对应原版 intent scheme，Flutter 直接跳转不需要）
        items.add(NoticeItem(
          avatar: dl.querySelector('img')?.attributes['src'] ?? '',
          content: ntc.innerHtml,
          dateTime: dl.querySelector('span.xg1')?.text ?? '',
        ));
      } catch (_) {}
    }
    final next = doc.querySelector('a.nxt')?.attributes['href'] ?? '';
    return (items: items, nextPageUrl: next);
  }
}
