import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../models/misc_models.dart';

/// 关注仓库 —— 对应原生 FollowingFeedViewModel.kt / FollowListViewModel.kt
class FollowRepository {
  FollowRepository._();

  static final FollowRepository instance = FollowRepository._();

  /// 广播动态（CDATA XML 包裹的 HTML 碎片）
  Future<List<FeedInfo>> fetchFeed({int page = 1}) async {
    final query = WebsiteConstants.followFeedQuery
        .replaceAll('%d', '$page')
        .replaceAll('%d', '1');
    final xml = await ApiClient.instance.getRaw(query);
    final result = _extractCdata(xml);
    if (result == 'false') return [];
    final doc = html_parser.parse(result);
    final feeds = <FeedInfo>[];
    for (final li in doc.querySelectorAll('li.cl')) {
      try {
        final avatar = li.querySelector('a.z > img')?.attributes['src'] ?? '';
        var username = '';
        var dateTime = '';
        final author = li.querySelector('div.flw_author');
        if (author != null) {
          username = author.querySelector('a')?.text ?? '';
          dateTime = author.querySelector('span')?.text ?? '';
        }
        final title = li.querySelector('h2')?.text ?? '';
        final articleUrl = li.querySelector('h2 > a')?.attributes['href'] ?? '';
        final images = li.querySelectorAll('.flw_image ul > li img')
            .map((img) => img.attributes['src'] ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        var content = '';
        final pbm = li.querySelector('.pbm');
        if (pbm != null) {
          pbm.querySelectorAll('div.flw_image').toList().forEach(_remove);
          pbm.querySelectorAll('img').toList().forEach(_remove);
          pbm.querySelectorAll('a.flw_readfull').toList().forEach(_remove);
          content = pbm.innerHtml;
        }
        final forum = li.querySelector('div.xg1 > a')?.text ?? '';
        final quote = li.querySelector('div.flw_quotenote')?.text ?? '';
        feeds.add(FeedInfo(
          username: username,
          avatar: avatar,
          dateTime: dateTime,
          title: title,
          articleUrl: articleUrl,
          content: content,
          forum: forum,
          quote: quote,
          images: images,
        ));
      } catch (_) {}
    }
    return feeds;
  }

  String _extractCdata(String xml) {
    final start = xml.indexOf('[CDATA[');
    if (start < 0) return '';
    final contentStart = start + '[CDATA['.length;
    final end = xml.indexOf(']]>', contentStart);
    if (end < 0) return xml.substring(contentStart);
    return xml.substring(contentStart, end);
  }

  void _remove(dom.Node node) {
    node.remove();
  }
}
