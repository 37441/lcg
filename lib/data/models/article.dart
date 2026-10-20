/// 文章模型 —— 对应原生 Article/ArticleDetail/Post/PreviewPost/ForumPage/ForumThread/ArticleEntity
class Article {
  Article({
    required this.title,
    required this.author,
    this.date = '',
    this.url = '',
    this.view = 0,
    this.reply = 0,
    this.origin = '',
    this.helpCoin = 0,
    this.isRecommended = false,
  });

  final String title;
  final String author;
  final String date;
  final String url;
  final int view;
  final int reply;
  final String origin;
  final int helpCoin;
  final bool isRecommended;

  String get fullUrl =>
      url.startsWith('http') ? url : 'https://www.52pojie.cn/$url';
}

class ArticleDetail {
  ArticleDetail({
    required this.title,
    required this.posts,
    this.nextPageUrl = '',
    this.formHash = '',
    this.replyFormAction = '',
  });

  final String title;
  final List<Post> posts;
  final String nextPageUrl;
  final String formHash;

  /// 回复提交表单 action（论坛快回复）
  final String replyFormAction;
}

class Post {
  Post({
    required this.author,
    this.avatar = '',
    this.date = '',
    this.content = '',
    this.replyUrl,
    this.replyAddUrl,
    this.profileUrl = '',
    this.extraInfo = '',
    this.followInfo,
  });

  final String author;
  final String avatar;
  final String date;
  final String content;
  final String? replyUrl;
  final String? replyAddUrl;
  final String profileUrl;
  final String extraInfo;
  final String? followInfo; // "title|url"
}

class PreviewPost {
  PreviewPost({
    this.avatar = '',
    this.author = 'Unknown',
    this.date = '',
    this.content = '',
  });

  final String avatar;
  final String author;
  final String date;
  final String content;
}

class ForumPage {
  ForumPage({required this.articles, this.threads = const []});

  final List<Article> articles;
  final List<ForumThread> threads;
}

class ForumThread {
  ForumThread({required this.name, required this.url});

  final String name;
  final String url;
}

/// 收藏/历史共用实体（对应 ArticleEntity：含网络收藏的 delUrl）
class ArticleEntity {
  ArticleEntity({
    this.title = '',
    this.author = '',
    this.url = '',
    this.content = '',
    this.timestamp = 0,
    this.delUrl,
  });

  final String title;
  final String author;
  final String url;
  final String content;
  final int timestamp;
  final String? delUrl;

  String get fullUrl =>
      url.startsWith('http') ? url : 'https://www.52pojie.cn/$url';
}
