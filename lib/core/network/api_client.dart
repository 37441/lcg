import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';

import 'cookie_store.dart';
import '../config/website_constants.dart';

/// 网络异常（对应原生 NetworkException）
class NetworkException implements Exception {
  NetworkException([this.message = '网络异常']);
  final String message;

  @override
  String toString() => message;
}

/// 需要登录（对应原生 LoginRequiredException）
class LoginRequiredException implements Exception {}

/// 帖子被屏蔽/权限不足（对应原生 BlockException）
class BlockException implements Exception {
  BlockException([this.message = '']);
  final String message;

  @override
  String toString() => message;
}

/// 反爬（对应原生 AntiScrapingException）
class AntiScrapingException implements Exception {}

/// 阿里云 WAF JS 挑战：需 WebView 执行 JS 过验证后重试
class WafChallengeException implements Exception {
  WafChallengeException(this.url);
  final String url;
}

/// 请求太频繁（对应原生 RequestTooOftenException）
class RequestTooOftenException implements Exception {}

/// ApiClient —— 对应原生 JsoupClient.kt（GET/POST + Cookie 池 + formhash + 反爬）
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 15);
  /// 统一桌面 UA：原生请求与 WebView（WAF/登录）必须一致，否则 WAF 验证 cookie 不认
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  late final Dio _dio;
  String? formHash;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final jar = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    CookieStore.init(jar);

    _dio = Dio(BaseOptions(
      baseUrl: WebsiteConstants.serverBaseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      followRedirects: true,
      validateStatus: (_) => true, // 允许非 2xx 也读取 body 解析错误页
      headers: {
        'User-Agent': userAgent,
        'Referer': WebsiteConstants.serverBaseUrl,
        'Accept-Language': 'zh-CN,zh;q=0.9',
      },
    ));
    _dio.interceptors.add(CookieManager(jar));
    // 登录后优先使用 WebView 同步的原始 Cookie 头（避免 cookie_jar 域匹配问题）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final h = CookieStore.webCookieHeader;
        if (h != null && h.isNotEmpty) {
          options.headers['Cookie'] = h;
        }
        handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  /// GET（query 为相对路径），返回解析后的 HTML 文档
  Future<dom.Document> getWithQuery(String query) async {
    return _get(WebsiteConstants.serverBaseUrl + query);
  }

  /// GET（完整 URL）
  Future<dom.Document> getUrl(String url) async {
    return _get(url);
  }

  /// 裸 GET 响应（如签到，需要看 alert_info 文本）
  Future<dom.Document> getUrlDocument(String url) => getUrl(url);

  Future<dom.Document> _get(String url) async {
    try {
      final resp = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final text = _decode(resp.data ?? [], resp.headers.value('content-type'));
      if (_isWafChallenge(text)) {
        throw WafChallengeException(url);
      }
      return html_parser.parse(text);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('当前网络质量差，请稍后再试');
      }
      throw NetworkException(e.message ?? '请求失败');
    }
  }

  /// 裸 GET 响应字符串（对应 sendAjaxRequest，关注广播回的是 CDATA XML）
  Future<String> getRaw(String query) async {
    final resp = await _dio.get<List<int>>(
      WebsiteConstants.serverBaseUrl + query,
      options: Options(responseType: ResponseType.bytes),
    );
    final text = _decode(resp.data ?? [], resp.headers.value('content-type'));
    if (_isWafChallenge(text)) {
      throw WafChallengeException(WebsiteConstants.serverBaseUrl + query);
    }
    return text;
  }

  /// POST 表单，返回响应（对应 sendPostRequestWithUrl）
  Future<Response<String>> postForm(String url, Map<String, String> form) async {
    try {
      final resp = await _dio.post<List<int>>(
        url,
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.bytes,
        ),
      );
      return Response<String>(
        requestOptions: resp.requestOptions,
        data: _decode(resp.data ?? [], resp.headers.value('content-type')),
        headers: resp.headers,
        statusCode: resp.statusCode,
        statusMessage: resp.statusMessage,
        isRedirect: resp.isRedirect,
        redirects: resp.redirects,
        extra: resp.extra,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('当前网络质量差，请稍后再试');
      }
      throw NetworkException(e.message ?? '请求失败');
    }
  }

  /// POST 表单，返回解析后的文档（用于搜索等）
  Future<dom.Document> postFormDocument(String url, Map<String, String> form) async {
    final resp = await postForm(url, form);
    return html_parser.parse(resp.data ?? '');
  }

  /// 判断是否为阿里云 WAF 的 JS 挑战页
  bool _isWafChallenge(String text) {
    return text.contains('Please enable JavaScript') ||
        (text.length < 60000 &&
            text.contains('<h1><strong>Please enable JavaScript') ); 
  }

  /// 按响应 Content-Type 解码：52pojie 为 GBK，百度站内为 UTF-8
  String _decode(List<int> bytes, String? contentType) {
    final lower = (contentType ?? '').toLowerCase();
    if (lower.contains('utf-8') || lower.contains('json')) {
      try {
        return utf8.decode(bytes);
      } catch (_) {}
    }
    try {
      return gbk.decode(bytes);
    } catch (_) {
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }
}
