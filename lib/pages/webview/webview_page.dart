import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 通用网页页（对应 WebViewActivity 普通模式）
class WebViewPage extends StatelessWidget {
  const WebViewPage({super.key, required this.url, this.title});

  final String url;
  final String? title;

  static void open(BuildContext context, String url, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewPage(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? '网页')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          useShouldOverrideUrlLoading: false,
        ),
      ),
    );
  }
}