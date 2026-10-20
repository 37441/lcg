import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/website_constants.dart';
import '../core/utils/toast.dart';
import '../pages/webview/webview_page.dart';
import '../theme/ui_tokens.dart';

/// 帖子内容 HTML 渲染（对应原生 HtmlTextView + ClickablePreCodeSpan）
/// - 图片自动带 Referer 请求头（绕过 52pojie 防盗链）
/// - 链接点击弹出「应用内打开 / 浏览器打开 / 复制链接」选择
class HtmlView extends StatelessWidget {
  const HtmlView({super.key, required this.html, this.padding = EdgeInsets.zero});

  final String html;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: HtmlWidget(
        html,
        textStyle: TextStyle(
          fontSize: UiTokens.fontBody,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        factoryBuilder: () => _RefererFactory(),
        onTapUrl: (url) => _handleUrlTap(context, url),
      ),
    );
  }
}

/// 图片加载工厂：给网络图片加 Referer/UA，避免 52pojie 图片防盗链显示叉号
class _RefererFactory extends WidgetFactory {
  @override
  ImageProvider? imageProviderFromNetwork(String url) {
    if (url.isEmpty) return null;
    return CachedNetworkImageProvider(
      url,
      headers: const {
        'Referer': WebsiteConstants.serverBaseUrl,
        'User-Agent': WebsiteConstants.desktopUserAgent,
      },
    );
  }
}

/// 链接点击：弹出跳转方式选择
Future<bool> _handleUrlTap(BuildContext context, String url) async {
  if (url.isEmpty || url.startsWith('#') || url.startsWith('javascript')) {
    return false;
  }
  final choice = await showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('打开链接'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 1),
          child: const Text('在应用内打开'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 2),
          child: const Text('使用浏览器打开'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 3),
          child: const Text('复制链接'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 0),
          child: const Text('取消'),
        ),
      ],
    ),
  );
  if (!context.mounted) return true;
  switch (choice) {
    case 1:
      WebViewPage.open(context, url);
      break;
    case 2:
      final uri = Uri.tryParse(url);
      if (uri == null) {
        showToast(context, '无效链接');
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      break;
    case 3:
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) showToast(context, '链接已复制');
      break;
  }
  return true;
}

/// 通用加载/空态/错误态
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.text = '目前没有内容可供展示'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: UiTokens.spaceM),
          Text(
            text,
            style: TextStyle(
              fontSize: UiTokens.fontAux,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message = '请求页面失败，请稍后再试', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: UiTokens.spaceS),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: UiTokens.fontAux,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: UiTokens.spaceM),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}