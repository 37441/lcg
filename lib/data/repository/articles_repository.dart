import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../db/app_database.dart';
import '../models/article.dart';
import '../parser/articles_parser.dart';

/// 文章仓库 —— 对应原生 ArticlesRemoteDataSource.kt
class ArticlesRepository {
  ArticlesRepository._();

  static final ArticlesRepository instance = ArticlesRepository._();

  final _api = ApiClient.instance;

  /// 首页推荐列表（分页）
  Future<List<Article>> fetchHomeArticles(String param, int pageNum) async {
    final doc = await _api.getWithQuery('${WebsiteConstants.forumBaseQuery}$param&page=$pageNum');
    return ArticlesParser.parseHomeArticles(doc.documentElement!.outerHtml);
  }

  /// 板块文章列表（分页）
  Future<List<Article>> fetchForumArticles(String query) async {
    final doc = await _api.getWithQuery(query);
    return ArticlesParser.parseForumPage(doc.documentElement!.outerHtml).articles;
  }

  /// 板块文章 + 帖子分类 Thread（对应 processForumArticlesDocument）
  Future<ForumPage> fetchForumPage(String query) async {
    final doc = await _api.getWithQuery(query);
    return ArticlesParser.parseForumPage(doc.documentElement!.outerHtml);
  }

  /// 文章详情
  Future<ArticleDetail> fetchArticleDetail(String query, {bool isFirstFetch = true}) async {
    final doc = await _api.getWithQuery(query);
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
    final doc = await _api.getWithQuery(query);
    return ArticlesParser.parseFirstPost(doc.documentElement!.outerHtml);
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
      final doc = await _api.getWithQuery(query);
      return doc.querySelector('.nfl')?.text ?? 'Error';
    } catch (_) {
      return 'Error';
    }
  }

  /// 回复帖子：POST 到回复 URL（对应 ReplyPostViewModel）
  Future<bool> replyPost({
    required String replyUrl,
    required String formHash,
    required String message,
  }) async {
    try {
      final form = <String, String>{
        'formhash': formHash,
        'message': message,
        'replysubmit': 'yes',
      };
      final resp = await _api.postForm(WebsiteConstants.serverBaseUrl + replyUrl, form);
      final body = resp.data ?? '';
      return !body.contains('messagetext') && !body.contains('没有权限');
    } catch (_) {
      return false;
    }
  }
}
