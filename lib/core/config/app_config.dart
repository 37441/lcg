import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置 —— 对应原生 AppConfig.kt（UMRemoteConfig 远程配置不移植，用默认值）
class AppConfig {
  AppConfig._();

  static const _searchResultInWebView = 'open_result_in_webview';
  static const _articleInWebView = 'open_article_in_webview';
  static const _handlePreTag = 'handle_pre_tag_in_article';
  static const _showRecommendFlag = 'article_show_recommend_flag';
  static const _defaultSearchEngine = 'default_search_engine';
  static const _autoSignIn = 'auto_sign_in';
  static const _syncFavorites = 'sync_favorites';

  static const searchEngineBaidu = 1;
  static const searchEngineWuai = 0;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get appReleaseUrl => 'thread-1073834-1-1.html';

  static String get jrsUrl => 'http://www.jrskq.com/';

  static bool get searchResultShowInWebView =>
      _prefs?.getBool(_searchResultInWebView) ?? false;

  static set searchResultShowInWebView(bool value) =>
      _prefs?.setBool(_searchResultInWebView, value);

  static bool get articleShowInWebView => _prefs?.getBool(_articleInWebView) ?? false;

  static set articleShowInWebView(bool value) => _prefs?.setBool(_articleInWebView, value);

  static bool get articleHandlePreTag => _prefs?.getBool(_handlePreTag) ?? true;

  static set articleHandlePreTag(bool value) => _prefs?.setBool(_handlePreTag, value);

  static bool get articleShowRecommendFlag =>
      _prefs?.getBool(_showRecommendFlag) ?? true;

  static set articleShowRecommendFlag(bool value) =>
      _prefs?.setBool(_showRecommendFlag, value);

  static int get defaultSearchEngine =>
      _prefs?.getInt(_defaultSearchEngine) ?? searchEngineBaidu;

  static set defaultSearchEngine(int value) => _prefs?.setInt(_defaultSearchEngine, value);

  static bool get autoSignEnable => _prefs?.getBool(_autoSignIn) ?? true;

  static set autoSignEnable(bool value) => _prefs?.setBool(_autoSignIn, value);

  static bool get syncFavorites => _prefs?.getBool(_syncFavorites) ?? true;

  static set syncFavorites(bool value) => _prefs?.setBool(_syncFavorites, value);
}
