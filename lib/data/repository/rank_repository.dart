import 'package:html/parser.dart' as html_parser;

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../models/discover.dart';

/// 排行榜仓库 —— 对应原生 RankRepo.kt
class RankRepository {
  RankRepository._();

  static final RankRepository instance = RankRepository._();

  Future<RankListModel> fetchRank(RankType rankType, DateType dateType) async {
    final query =
        WebsiteConstants.rankQuery.replaceAll('%s', rankType.value).replaceAll('%s', dateType.value);
    final doc = await ApiClient.instance.getWithQuery(query);
    return _parse(doc.documentElement!.outerHtml, rankType);
  }

  RankListModel _parse(String html, RankType rankType) {
    final doc = html_parser.parse(html);
    final time = doc.querySelector('div.notice')?.text ?? '';
    final list = <RankModel>[];
    for (final tr in doc.querySelectorAll('table tbody tr')) {
      try {
        final cells = tr.children;
        if (cells.length < 5) continue;
        final indexEl = cells[0];
        final indexText = indexEl.children.isNotEmpty
            ? indexEl.children.first.attributes['alt'] ?? indexEl.text
            : indexEl.text;
        final title = cells[1].text;
        final url = cells[1].children.isNotEmpty
            ? cells[1].children.first.attributes['href'] ?? ''
            : '';
        final forum = cells[2].text;
        final authorName = cells[3].children.isNotEmpty &&
                cells[3].children.first.children.isNotEmpty
            ? cells[3].children.first.children.first.text
            : '';
        final authorUrl = cells[3].children.isNotEmpty &&
                cells[3].children.first.children.isNotEmpty
            ? cells[3].children.first.children.first.attributes['href'] ?? ''
            : '';
        final date = cells[3].children.length > 1 ? cells[3].children[1].text : '';
        final numText = cells[4].children.isNotEmpty
            ? cells[4].children.first.text
            : cells[4].text;
        list.add(RankModel(
          index: int.tryParse(indexText.trim()) ?? 0,
          title: title,
          url: url,
          forum: forum,
          authorName: authorName,
          authorUrl: authorUrl,
          date: date,
          type: rankType,
          num: int.tryParse(numText.trim()) ?? 0,
        ));
      } catch (_) {}
    }
    return RankListModel(list: list, time: time);
  }
}
