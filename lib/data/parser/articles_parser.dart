import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../core/network/api_client.dart';
import '../models/article.dart';

/// 文章解析 —— 对应原生 ArticlesRemoteDataSource.kt（jsoup → package:html）
class ArticlesParser {
  ArticlesParser._();

  static const _hotPattern = '热度';
  static const _recommendedPattern = '评价指数';
  static const _hotLimit = 100;
  static const _recommendedLimit = 10;

  /// 首页/板块文章列表：tbody[id^=normal]
  static List<Article> parseArticleList(String html) {
    final doc = html_parser.parse(html);
    final rows = doc.querySelectorAll('tbody[id^="normal"]');
    final list = <Article>[];
    for (final e in rows) {
      try {
        final reply = int.tryParse(_extract(e, 'td.num', 'a.xi2') ?? '') ?? 0;
        final view = int.tryParse(_extract(e, 'td.num', 'em') ?? '') ?? 0;
        final title = e.querySelector('th.common > .xst')?.text ?? '';
        final author = _extract(e, 'td.by', 'a[href*="uid"]') ?? '';
        final date = _extract(e, 'td.by', 'span') ?? '';
        final url = _extractAttr(e, 'href', 'th.common', 'a.xst') ?? '';
        final origin = e.querySelector('td.by > a[target]')?.text ?? '';
        if (title.isNotEmpty && author.isNotEmpty) {
          list.add(Article(
            title: title,
            author: author,
            date: date,
            url: url,
            view: view,
            reply: reply,
            origin: origin,
          ));
        }
      } catch (_) {}
    }
    return list;
  }

  /// 首页推荐列表（含已解决/推荐标签逻辑，对应 getArticles）
  static List<Article> parseHomeArticles(String html) {
    final doc = html_parser.parse(html);
    final rows = doc.querySelectorAll('tbody[id^="normal"]');
    final list = <Article>[];
    for (final e in rows) {
      try {
        final reply = int.tryParse(_extract(e, 'td.num', 'a.xi2') ?? '') ?? 0;
        final view = int.tryParse(_extract(e, 'td.num', 'em') ?? '') ?? 0;
        final title = e.querySelector('th.common > .xst')?.text ?? '';
        final author = _extract(e, 'td.by', 'a[href*="uid"]') ?? '';
        final date = _extract(e, 'td.by', 'span') ?? '';
        final url = _extractAttr(e, 'href', 'th.common', 'a.xst') ?? '';
        final origin = e.querySelector('td.by > a[target]')?.text ?? '';

        final helpInfo = e.querySelector('th.common > span.xi1 > span.xw1')?.text ?? '';
        var helpCoin = 0;
        if (helpInfo.isEmpty) {
          if ((e.querySelector('th.common')?.text ?? '').contains('- [已解决]')) {
            helpCoin = -1;
          }
        } else {
          helpCoin = int.tryParse(helpInfo) ?? 0;
        }

        var isRecommended = false;
        final imgs = e.querySelectorAll('th.common img');
        for (final img in imgs) {
          final s = img.attributes['title'] ?? '';
          if (s.contains(_hotPattern)) {
            final n = int.tryParse(s.replaceAll(_hotPattern, '').trim());
            if (n != null && n >= _hotLimit) isRecommended = true;
          } else if (s.contains(_recommendedPattern)) {
            final n = int.tryParse(s.replaceAll(_recommendedPattern, '').trim());
            if (n != null && n >= _recommendedLimit) isRecommended = true;
          }
        }

        if (title.isNotEmpty && author.isNotEmpty) {
          list.add(Article(
            title: title,
            author: author,
            date: date,
            url: url,
            view: view,
            reply: reply,
            origin: origin,
            helpCoin: helpCoin,
            isRecommended: isRecommended,
          ));
        }
      } catch (_) {}
    }
    return list;
  }

  /// 板块文章页（ForumArticles）：列表 + 需要登录时抛 LoginRequiredException
  static ForumPage parseForumPage(String html) {
    final doc = html_parser.parse(html);
    var rows = doc.querySelectorAll('tbody[id^="normal"]');
    if (rows.isEmpty) {
      if (doc.getElementById('messagelogin') != null) {
        throw LoginRequiredException();
      }
      return ForumPage(articles: []);
    }

    final articles = <Article>[];
    for (final element in rows) {
      try {
        final reply = int.parse(_extract(element, 'td.num', 'a.xi2') ?? '0');
        final view = int.parse(_extract(element, 'td.num', 'em') ?? '0');
        final title = _extract(element, 'th.new', '.xst') ?? '';
        final finalTitle =
            title.isNotEmpty ? title : (_extract(element, 'th.common', '.xst') ?? '');
        final author = _extract(element, 'td.by', 'a[href*="uid"]') ?? '';
        final date = _extract(element, 'td.by', 'span') ?? '';
        var url = _extractAttr(element, 'href', 'th.new', 'a.xst') ?? '';
        if (url.isEmpty) {
          url = _extractAttr(element, 'href', 'th.common', 'a.xst') ?? '';
        }
        final origin = _extract(element, 'td.by', 'a[target]') ?? '';
        if (finalTitle.isNotEmpty && author.isNotEmpty) {
          articles.add(Article(
            title: finalTitle,
            author: author,
            date: date,
            url: url,
            view: view,
            reply: reply,
            origin: origin,
          ));
        }
      } catch (_) {}
    }

    final threads = <ForumThread>[];
    final threadTypes = doc.getElementById('thread_types');
    if (threadTypes != null) {
      final lis = threadTypes.querySelectorAll('li');
      for (final li in lis) {
        try {
          final a = li.querySelector('a');
          if (a == null) continue;
          a.querySelectorAll('span').toList().forEach(_removeNode);
          final name = a.text.trim();
          final threadUrl = a.attributes['href'] ?? '';
          if (name.isNotEmpty && threadUrl.isNotEmpty) {
            threads.add(ForumThread(name: name, url: threadUrl));
          }
        } catch (_) {}
      }
    }
    return ForumPage(articles: articles, threads: threads);
  }

  /// 文章详情（对应 getArticleDetail）
  static ArticleDetail parseArticleDetail(String html) {
    final doc = html_parser.parse(html);
    final title = doc.getElementById('thread_subject')?.text ?? '';
    if (title.isEmpty) {
      final message = doc.getElementById('messagetext')?.text ?? '';
      throw BlockException(message);
    }
    final nextPageUrl = doc.querySelector('a.nxt')?.attributes['href'] ?? '';
    final formHash = doc.querySelector('input[name="formhash"]')?.attributes['value'] ?? '';
    final replyAddUrls = _getReplyAddUrls(doc);
    final userInfos = _getUserInfos(doc);
    final contents = _getContents(doc);
    final dateTimes = doc.querySelectorAll('div.authi em').map((e) => e.text).toList();
    final replyUrls = doc.querySelectorAll('.fastre').map((e) => e.attributes['href'] ?? '').toList();

    final posts = <Post>[];
    for (var i = 0; i < userInfos.length; i++) {
      try {
        final replyAddUrl = i < replyAddUrls.length ? replyAddUrls[i] : null;
        final replyUrl = i < replyUrls.length ? replyUrls[i] : null;
        posts.add(Post(
          author: userInfos[i]['name'] ?? '',
          avatar: userInfos[i]['avatar'] ?? '',
          date: i < dateTimes.length ? dateTimes[i] : '',
          content: i < contents.length ? contents[i] : '',
          replyUrl: replyUrl,
          replyAddUrl: replyAddUrl,
          profileUrl: userInfos[i]['profile_url'] ?? '',
          extraInfo: userInfos[i]['extra_info'] ?? '',
          followInfo: userInfos[i]['follow_info'],
        ));
      } catch (_) {}
    }
    return ArticleDetail(
      title: title,
      posts: posts,
      nextPageUrl: nextPageUrl,
      formHash: formHash,
    );
  }

  /// 首楼预览（对应 getFirstPost）
  static PreviewPost parseFirstPost(String html) {
    final doc = html_parser.parse(html);
    final dateTime = doc.querySelector('div.authi em')?.text;
    if (dateTime == null) {
      final message = doc.getElementById('messagetext')?.text ?? '';
      throw BlockException(message);
    }
    final content = _getFirstContent(doc);
    var avatar = '';
    var name = 'Unknown';
    final userTd = doc.querySelector('td[rowspan]');
    if (userTd != null) {
      avatar = userTd.querySelector('div.avatar img')?.attributes['src'] ?? '';
      name = userTd.querySelector('a.xw1')?.text ?? name;
    }
    return PreviewPost(avatar: avatar, author: name, date: dateTime, content: content);
  }

  /// 网络收藏列表（对应 parseFavorites）
  static List<ArticleEntity> parseFavorites(String html) {
    final doc = html_parser.parse(html);
    final ul = doc.getElementById('favorite_ul');
    if (ul == null) return [];
    final list = <ArticleEntity>[];
    for (final it in ul.children) {
      try {
        final delUrl = it.querySelector('a.y')?.attributes['href'] ?? '';
        final dateAdded = it.querySelector('span.xg1')?.text ?? '';
        final target = it.querySelector('[target]');
        if (target == null) continue;
        list.add(ArticleEntity(
          title: target.text,
          url: target.attributes['href'] ?? '',
          timestamp: _ts(dateAdded),
          delUrl: delUrl,
        ));
      } catch (_) {}
    }
    return list;
  }

  // ---------- 内部工具 ----------

  static String _getFirstContent(dom.Document doc) {
    final pcb = doc.querySelector('div.pcb');
    if (pcb == null) return '';
    final t = pcb.querySelector('td.t_f');
    if (t != null) {
      return _processContentElement(t).innerHtml;
    }
    return pcb.querySelector('div.locked')?.innerHtml ?? '';
  }

  static List<String> _getContents(dom.Document doc) {
    final list = <String>[];
    for (final pcb in doc.querySelectorAll('div.pcb')) {
      final t = pcb.querySelector('td.t_f');
      if (t != null) {
        final res = _processContentElement(t);
        for (final img in pcb.querySelectorAll('div.savephotop > img')) {
          final file = img.attributes['file'];
          if (file != null) {
            img.attributes['src'] = file;
          }
          res.append(img);
        }
        list.add(res.innerHtml);
      } else {
        final locked = pcb.querySelector('div.locked');
        list.add(locked?.innerHtml ?? '');
      }
    }
    return list;
  }

  /// 内容清理（对应 processContentElement）：删 tip/script、pre 换行转 <br/>、图片 file→src、去静态占位图
  static dom.Element _processContentElement(dom.Element element) {
    // querySelectorAll 返回 live 集合，先快照避免遍历中移除导致跳项
    element.querySelectorAll('div.tip').toList().forEach(_removeNode);
    element.querySelectorAll('script').toList().forEach(_removeNode);
    for (final pre in element.querySelectorAll('pre').toList()) {
      final s = pre.innerHtml
          .replaceAll('\r\n', '<br/>')
          .replaceAll('\r', '<br/>')
          .replaceAll('\n', '<br/>')
          .replaceAll(' ', '&nbsp;');
      pre.innerHtml = s;
    }
    for (final img in element.querySelectorAll('img').toList()) {
      final src = img.attributes['src'] ?? '';
      if (src.contains('https://static.52pojie.cn/static/') && !src.contains('none')) {
        _removeNode(img);
        continue;
      }
      final file = img.attributes['file'];
      if (file != null && file.isNotEmpty) {
        img.attributes['src'] = file;
      }
    }
    return element;
  }

  static List<String> _getReplyAddUrls(dom.Document doc) {
    final list = <String>[];
    final e = doc.getElementById('recommend_add');
    if (e != null) list.add(e.attributes['href'] ?? '');
    for (final el in doc.querySelectorAll('a.replyadd')) {
      list.add(el.attributes['href'] ?? '');
    }
    return list;
  }

  static List<Map<String, String>> _getUserInfos(dom.Document doc) {
    final list = <Map<String, String>>[];
    for (final element in doc.querySelectorAll('td[rowspan]')) {
      final map = <String, String>{};
      final avatar = element.querySelector('div.avatar');
      if (avatar != null) {
        map['avatar'] = avatar.querySelector('img')?.attributes['src'] ?? '';
        map['profile_url'] = avatar.querySelector('a')?.attributes['href'] ?? '';
      }
      final follow = element.querySelector('a[id^="follow"]');
      if (follow != null) {
        map['follow_url'] = follow.attributes['href'] ?? '';
        map['follow_title'] = follow.attributes['title'] ?? '';
      }
      final dl = element.querySelector('dl');
      if (dl != null) map['extra_info'] = dl.outerHtml;
      map['name'] = element.querySelector('a.xw1')?.text ?? '';
      list.add(map);
    }
    return list;
  }

  /// 对应原生 extractFrom：在 element 的全部 selector1 匹配后代中找 selector2
  static String? _extract(dom.Element element, String selector1, String selector2) {
    for (final el in element.querySelectorAll(selector1)) {
      final t = el.querySelector(selector2);
      if (t != null) return t.text;
    }
    return null;
  }

  static String? _extractAttr(
      dom.Element element, String attr, String selector1, String selector2) {
    for (final el in element.querySelectorAll(selector1)) {
      final t = el.querySelector(selector2);
      if (t != null) {
        final v = t.attributes[attr];
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static void _removeNode(dom.Node node) {
    node.remove();
  }

  static int _ts(String date) {
    try {
      return DateTime.parse(date).millisecondsSinceEpoch;
    } catch (_) {
      try {
        return DateTime.parse(date).millisecondsSinceEpoch;
      } catch (_) {
        return 0;
      }
    }
  }
}
