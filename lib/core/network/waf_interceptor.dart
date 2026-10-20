import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/material.dart';

import '../../core/utils/app_log.dart';
import 'waf_silent_solver.dart';

/// 全局 Navigator key：WAF 拦截器需要用它在任意请求命中挑战时弹出验证页
class WafNavigator {
  WafNavigator._();
  static final key = GlobalKey<NavigatorState>();
}

/// 阿里云 WAF JS 挑战拦截器（参考 MT 客户端已验证方案）
///
/// 52pojie 对请求返回 `Please enable JavaScript` 混淆挑战页；
/// 该页需浏览器内核执行 JS 才能通过。拦截器检测到挑战后：
/// 1. 由 WafSilentSolver 用 1×1 后台 WebView 静默完成验证（无任何可见界面）
/// 2. 收割 WebView cookie 写回 dio 的 CookieJar
/// 3. 自动重发原请求，响应交给原调用方
/// 挑战只需通过一次，之后全部直通。
class WafDioInterceptor extends InterceptorsWrapper {
  WafDioInterceptor({required this.baseUrl, required Dio dio}) : _dio = dio;

  final String baseUrl;
  final Dio _dio;

  bool _passed = false;
  Future<void>? _solving;

  static bool isWafChallenge(String text) =>
      text.contains('Please enable JavaScript');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is List<int> && !_passed) {
      String? text;
      try {
        final ct = (response.headers.value('content-type') ?? '').toLowerCase();
        text = ct.contains('utf-8') ? utf8.decode(data) : gbk.decode(data);
      } catch (_) {}
      if (text != null && isWafChallenge(text)) {
        logD('waf', '检测到挑战页: ${response.requestOptions.uri}');
        unawaited(_solveAndResubmit(response.requestOptions, handler));
        return;
      }
    }
    handler.next(response);
  }

  /// 完成挑战后重发原请求，结果直接交给原响应处理器
  Future<void> _solveAndResubmit(
    RequestOptions options,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      await _ensureSolved();
      final res = await _dio.fetch(options);
      logD('waf', '验证通过，重发 ${options.uri} -> ${res.statusCode}');
      handler.next(res);
    } catch (e, st) {
      logD('waf', '验证/重发失败: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<void> _ensureSolved() async {
    if (_passed) return;
    final running = _solving;
    if (running != null) return running;
    final future = _solveInternal();
    _solving = future;
    try {
      await future;
      _passed = true;
    } finally {
      _solving = null;
    }
  }

  Future<void> _solveInternal() async {
    final context = WafNavigator.key.currentContext;
    if (context == null) {
      throw StateError('页面尚未就绪，无法执行安全验证');
    }
    final ok = await WafSilentSolver.solve(context, '${baseUrl}forum.php');
    logD('waf', '静默验证结果: $ok');
    if (!ok) {
      throw StateError('安全验证未通过');
    }
  }
}