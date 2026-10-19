/// 消息/关注/搜索模型
class NotificationInfo {
  NotificationInfo({
    this.message = 0,
    this.follower = 0,
    this.myPost = 0,
    this.systemNotifs = 0,
  });

  final int message;
  final int follower;
  final int myPost;
  final int systemNotifs;

  int get total => message + follower + myPost + systemNotifs;

  bool get isEmpty => total == 0;
}

class MyPostInfo {
  MyPostInfo({required this.dateTime, required this.ntcBody, this.collapseMsg = ''});

  final String dateTime;
  final String ntcBody;
  final String collapseMsg;
}

class SystemNotifications {
  SystemNotifications({required this.dateTime, required this.ntcBody, this.quote = ''});

  final String dateTime;
  final String ntcBody;
  final String quote;
}

class FollowInfo {
  FollowInfo({
    required this.username,
    this.avatar = '',
    this.followOrUnFollowUrl = '',
    this.followingNum = 0,
    this.followerNum = 0,
    this.lastAction = '',
  });

  final String username;
  final String avatar;
  final String followOrUnFollowUrl;
  final int followingNum;
  final int followerNum;
  final String lastAction;
}

class FollowResult {
  FollowResult({required this.followInfos, this.nextPageUrl});

  final List<FollowInfo> followInfos;
  final String? nextPageUrl;
}

class FeedInfo {
  FeedInfo({
    required this.username,
    this.avatar = '',
    this.dateTime = '',
    this.title = '',
    this.articleUrl = '',
    this.content = '',
    this.forum = '',
    this.quote = '',
    this.images,
  });

  final String username;
  final String avatar;
  final String dateTime;
  final String title;
  final String articleUrl;
  final String content;
  final String forum;
  final String quote;
  final List<String>? images;
}

class LCGSearchResults {
  LCGSearchResults({required this.searchResultList, this.totalResult});

  final List<LCGSearchResultItem> searchResultList;
  String? totalResult;
}

class LCGSearchResultItem {
  LCGSearchResultItem({
    required this.title,
    this.content = '',
    this.url = '',
    this.author = '',
    this.date = '',
    this.replyView = '',
    this.forum = '',
  });

  final String title;
  final String content;
  final String url;
  final String author;
  final String date;
  final String replyView;
  final String forum;

  String get fullUrl => url.startsWith('http') ? url : 'https://www.52pojie.cn/$url';
}

class BaiduSearchResults {
  BaiduSearchResults({required this.baiduSearchResultList});

  final List<BaiduSearchResult> baiduSearchResultList;
  String? totalResult;
  String? nextPageUrl;
}

class BaiduSearchResult {
  BaiduSearchResult({required this.title, this.contentAbstract = '', this.url = ''});

  final String title;
  final String contentAbstract;
  final String url;
}