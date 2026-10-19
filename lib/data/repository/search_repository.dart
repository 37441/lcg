import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../models/misc_models.dart';

/// 搜索仓库 —— 对应原生 LCGSearchService.kt / BaiduSearchService.kt
class SearchRepository {
  SearchRepository._();

  static final SearchRepository instance = SearchRepository._();

  /// 站内搜索（对应 LCGSearchService.doSearchWith）
  Future<LCGSearchResults> searchWuai(String keyword) async {
    final formHash = ApiClient.instance.formHash ?? '';
    final form = <String, String>{
      'formhash': formHash,
      'mod': 'forum',
      'srchtype': 'title',
      'srhfid': '',
      'srhlocality': 'forum::index',
      'srchtxt': keyword,
      'searchsubmit': 'true',
    };
    final doc = await ApiClient.instance.postFormDocument(
      '${WebsiteConstants.serverBaseUrl}search.php?searchsubmit=yes',
      form,
    );
    final items = <LCGSearchResultItem>[];
    for (final pbw in doc.querySelectorAll('.pbw')) {
      try {
        final spans = pbw.querySelectorAll('span');
        final a = pbw.querySelector('a');
        final p = pbw.querySelector('p.xg1');
        if (spans.length == 3 && a != null) {
          items.add(LCGSearchResultItem(
            title: a.innerHtml,
            url: a.attributes['href'] ?? '',
            replyView: p?.text ?? '',
            content: p?.nextElementSibling?.innerHtml ?? '',
            author: spans[1].text,
            date: spans[0].text,
            forum: spans[2].text,
          ));
        }
      } catch (_) {}
    }
    final total = doc.querySelector('h2')?.text;
    return LCGSearchResults(searchResultList: items, totalResult: total);
  }

  /// 百度站内搜索（对应 BaiduSearchService.doSearchRequest）
  Future<BaiduSearchResults> searchBaidu(String keyword) async {
    final url = WebsiteConstants.searchQuery.replaceAll('%s', Uri.encodeComponent(keyword));
    final doc = await ApiClient.instance.getUrl(url);
    final items = <BaiduSearchResult>[];
    for (final result in doc.querySelectorAll('div.result')) {
      try {
        final h = result.querySelector('h3.c-title a');
        items.add(BaiduSearchResult(
          title: h?.text ?? '',
          url: h?.attributes['href'] ?? '',
          contentAbstract: result.querySelector('div.c-abstract')?.text ?? '',
        ));
      } catch (_) {}
    }
    return BaiduSearchResults(baiduSearchResultList: items);
  }
}