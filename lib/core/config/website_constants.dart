/// 网站常量 —— 对应原生 WebsiteConstant.kt
class WebsiteConstants {
  WebsiteConstants._();

  static const String serverBaseUrl = 'https://www.52pojie.cn/';

  /// 统一桌面 UA：原生请求与 WebView（WAF/登录）必须一致，否则 WAF 验证 cookie 不认
  static const String desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String forumBaseQuery = 'forum.php?mod=guide&view=';
  static const String baiduSearchBaseUrl = 'http://zhannei.baidu.com/cse/';
  static const String searchQuery =
      'http://zhannei.baidu.com/cse/site?q=%s&click=1&cc=52pojie.cn&s=&nsid=';
  static const String freeChatQuery = 'forum-10-1.html';
  static const String welfareQuery = 'forum-66-1.html';
  static const String mobSecurityQuery = 'forum-65-%d.html';
  static const String softwareQuery = 'forum-16-%d.html';
  static const String forumUrlQuery = 'forum.php?mod=forumdisplay&fid=%s';

  static const String originalReleaseQuery = 'forum-2-%d.html';
  static const String programLanguageQuery = 'forum-24-%d.html';
  static const String animationReleaseQuery = 'forum-6-%d.html';
  static const String reverseResourceQuery = 'forum-4-%d.html';
  static const String qaQuery = 'forum-8-%d.html';
  static const String virusAnalysisQuery = 'forum-32-%d.html';
  static const String virusRescueQuery = 'forum-50-%d.html';
  static const String virusSampleQuery = 'forum-40-%d.html';

  static const String myArticlesQuery = 'forum.php?mod=guide&view=my';
  static const String getFavoriteQuery = 'home.php?mod=space&do=favorite&view=me';
  static const String addToFavoriteQuery =
      'home.php?mod=spacecp&ac=favorite&type=thread&id=%s&formhash=%s&infloat=yes&handlekey=k_favorite&inajax=1&ajaxtarget=fwin_content_k_favorite';

  static const String checkRuleUrl =
      '${serverBaseUrl}forum.php?mod=ajax&action=checkpostrule&inajax=yes&ac=reply&infloat=yes&handlekey=reply';

  // notifications
  static const String notificationHomeQuery = 'home.php?mod=space&do=notice';
  static const String systemNotificationQuery = 'home.php?mod=space&do=notice&view=system';
  static const String mypostNotificationQuery = 'home.php?mod=space&do=notice&view=mypost';

  // private message
  static const String privateMessageQuery = 'home.php?mod=space&do=pm';

  // home / profile
  static const String homeQuery = 'home.php?mod=spacecp&ac=credit&showcredit=1';
  static const String profileQuery = 'home.php?mod=space&do=profile&from=space';
  static const String loginQuery = 'member.php?mod=logging&action=login';

  // follow
  static const String followPageUrl = 'home.php?mod=follow';
  static const String followFeedQuery =
      'home.php?mod=spacecp&ac=follow&op=getfeed&page=%d&archiver=%d&inajax=1&viewtype=follow';
  static const String followingUsersQuery = 'home.php?mod=follow&do=following';
  static const String followerUsersQuery = 'home.php?mod=follow&do=follower';

  // rank
  static const String rankQuery = 'misc.php?mod=ranklist&type=thread&view=%s&orderby=%s';

  // QQ
  static const String qqLoginUrl =
      '${serverBaseUrl}connect.php?mod=login&op=init&referer=index.php&statfrom=login_simple';

  // sign in task
  static const String signInApplyUrl =
      'https://www.52pojie.cn/home.php?mod=task&do=apply&id=2';
  static const String signInDrawUrl =
      'https://www.52pojie.cn/home.php?mod=task&do=draw&id=2';
}
