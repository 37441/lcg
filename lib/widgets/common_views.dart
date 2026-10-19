import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../theme/ui_tokens.dart';

/// 帖子内容 HTML 渲染（对应原生 HtmlTextView + ClickablePreCodeSpan）
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
      ),
    );
  }
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