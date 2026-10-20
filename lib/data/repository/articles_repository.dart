import 'package:html/dom.dart' as dom;

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_log.dart';
import '../db/app_database.dart';
import '../models/article.dart';
import '../parser/articles_parser.dart';

/// 文章仓库 —— 对应原生 ArticlesRemoteDataSource.kt
class ArticlesRepository {
  ArticlesRepository._();

  static final ArticlesRepository instance = ArticlesRepository._();

  final _api = ApiClient.instance;

  /// 支持完整 URL 与相对 query 两种入参，避免 baseUrl 二次拼接
  Future<dom.Document> _getDoc(String urlOrQuery) async {
    return urlOrQuery.startsWith('http')
        ? _api.getUrl(urlOrQuery)
        : _api.getWithQuery(urlOrQuery);
  }

  /// 首页推荐列表（分页）
  Future<List<Article>> fetchHomeArticles(String param, int pageNum) async {
    final doc = await _api.getWithQuery('${WebsiteConstants.forumBaseQuery}$param&page=$pageNum');
    return ArticlesParser.parseHomeArticles(doc.documentElement!.outerHtml);
  }

  /// 板块文章列表（分页）
  Future<List<Article>> fetchForumArticles(String query) async {
    final doc = await _getDoc(query);
    return ArticlesParser.parseForumPage(doc.documentElement!.outerHtml).articles;
  }

  /// 板块文章 + 帖子分类 Thread（对应 processForumArticlesDocument）
  Future<ForumPage> fetchForumPage(String query) async {
    final doc = await _getDoc(query);
    final page = ArticlesParser.parseForumPage(doc.documentElement!.outerHtml);
    logD('parse',
        '$query -> articles=${page.articles.length} threads=${page.threads.length} title=${page.pageTitle}');
    return page;
  }

  /// 文章详情
  Future<ArticleDetail> fetchArticleDetail(String query, {bool isFirstFetch = true}) async {
    final doc = await _getDoc(query);
    final detail = ArticlesParser.parseArticleDetail(doc.documentElement!.outerHtml);
    if (isFirstFetch && detail.title.isNotEmpty) {
      final author = detail.posts.isNotEmpty ? detail.posts.first.author : '';
      await HistoryRepository.instance.addHistory(
        url: query,
        title: detail.title,
        author: author,
      );
    }
    return detail;
  }

  /// 首楼预览
  Future<PreviewPost> fetchPostPreview(String query) async {
    final doc = await _getDoc(query);
    return ArticlesParser.parseFirstPost(doc.documentElement!.outerHtml);
  }

  /// 板块实时数据：从 forum.php 抓每个板块的「主题」数（fid -> 主题数）
  Future<Map<int, int>> fetchSectionCounts() async {
    final counts = <int, int>{};
    try {
      final doc = await _api.getWithQuery('forum.php');
      for (final a in doc.querySelectorAll('a[href*="forum-"]')) {
        final href = a.attributes['href'] ?? '';
        final m = RegExp(r'forum-(\d+)-1\.html').firstMatch(href);
        if (m == null) continue;
        final fid = int.tryParse(m.group(1)!) ?? 0;
        if (fid == 0 || counts.containsKey(fid)) continue;
        // 向上找板块行，取「主题: N」/「帖数: N」
        var node = a.parent;
        String? emText;
        for (var i = 0; i < 4 && node != null; i++) {
          final em = node.querySelector('em');
          if (em != null &&
              (em.text.contains('主题') || em.text.contains('帖数'))) {
            emText = em.text;
            break;
          }
          node = node.parent;
        }
        if (emText == null) continue;
        final n = RegExp(r'(\d+)').firstMatch(emText)?.group(1);
        counts[fid] = int.tryParse(n ?? '') ?? 0;
      }
      logD('parse', '板块统计 -> ${counts.length} 个板块有数据');
    } catch (e) {
      logD('parse', '板块统计获取失败: $e');
    }
    return counts;
  }

  /// 在线收藏（对应 addFavorites）
  Future<bool> addFavorite(String threadId, String formHash) async {
    try {
      final query = WebsiteConstants.addToFavoriteQuery
          .replaceFirst('%s', threadId)
          .replaceFirst('%s', formHash);
      await _api.getWithQuery(query);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 支持楼主（对应 replyAdd）
  Future<String> replyAdd(String query) async {
    try {
      final doc = await _getDoc(query);
      return doc.querySelector('.nfl')?.text ?? 'Error';
    } catch (_) {
      return 'Error';
    }
  }

  /// 回复帖子：POST 到快回复表单 action
  /// 返回 null 表示成功，否则为错误提示
  Future<String?> replyPost({
    required String replyAction,
    required String formHash,
    required String message,
  }) async {
    try {
      final url = replyAction.startsWith('http')
          ? replyAction
          : WebsiteConstants.serverBaseUrl + replyAction;
      final form = <String, String>{
        'formhash': formHash,
        'message': message,
        'replysubmit': 'yes',
      };
      final resp = await _api.postForm(url, form);
      final body = resp.data ?? '';
      final err = RegExp(r'<div class="alert_error"[^>]*>([\s\S]*?)</div>')
              .firstMatch(body)
              ?.group(1) ??
          RegExp(r'id="messagetext"[^>]*>([\s\S]*?)</')
              .firstMatch(body)
              ?.group(1);
      final success = body.contains('succeed') ||
          body.contains('回复成功') ||
          body.contains('感谢');
      if (success) return null;
      if (err != null && err.trim().isNotEmpty) {
        return err.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      }
      if (body.contains('没有权限') || body.contains('请先登录')) {
        return '未登录或无权限，请先登录';
      }
      return null;
    } catch (e) {
      return '回复失败：$e';
    }
  }
}
