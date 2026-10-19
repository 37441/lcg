import 'package:flutter/material.dart';

import '../data/models/article.dart';
import '../theme/ui_tokens.dart';

/// 文章卡片 —— 对应原生 item_article_view.xml
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: UiTokens.spaceM, vertical: 4),
      color: scheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiTokens.cornerM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              UiTokens.spaceM, UiTokens.spaceS, UiTokens.spaceM, UiTokens.spaceS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: UiTokens.fontAux,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (article.isRecommended) ...[
                    const SizedBox(width: UiTokens.spaceS),
                    _Tag(
                      text: '推荐',
                      bg: scheme.primaryContainer,
                      fg: scheme.onPrimaryContainer,
                    ),
                  ],
                  if (article.helpCoin != 0) ...[
                    const SizedBox(width: UiTokens.spaceXs),
                    _Tag(
                      text: article.helpCoin == -1 ? '已解决' : '悬赏${article.helpCoin}',
                      bg: scheme.primaryContainer,
                      fg: scheme.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: UiTokens.spaceS),
              Row(
                children: [
                  Text(
                    '${article.reply} / ${article.view}',
                    style: TextStyle(
                        fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: UiTokens.spaceS),
                  Expanded(
                    child: Text(
                      article.origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: UiTokens.spaceS),
                  Text(
                    article.author,
                    style: TextStyle(
                        fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: UiTokens.spaceS, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(UiTokens.cornerXs),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: fg),
      ),
    );
  }
}