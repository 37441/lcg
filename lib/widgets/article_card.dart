import 'package:flutter/material.dart';

import '../data/models/article.dart';
import '../theme/ui_tokens.dart';

/// 文章卡片 —— 纯白大圆角卡片 + 浅色胶囊标签/数据按钮
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, this.onTap});

  final Article article;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? const Color(0xFFE6E6E6) : UiTokens.textDark;
    final textGray = isDark ? const Color(0xFF9E9E9E) : UiTokens.textGray;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(UiTokens.cornerM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(UiTokens.spaceM),
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
                        fontSize: UiTokens.fontBody,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (article.isRecommended) ...[
                    const SizedBox(width: UiTokens.spaceS),
                    const _Pill(text: '推荐', bg: UiTokens.mintGreenLight, fg: UiTokens.mintGreen),
                  ],
                  if (article.helpCoin != 0) ...[
                    const SizedBox(width: UiTokens.spaceS),
                    _Pill(
                      text: article.helpCoin == -1 ? '已解决' : '悬赏${article.helpCoin}',
                      bg: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0),
                      fg: textGray,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: UiTokens.spaceM),
              // 底部数据栏：浅灰胶囊按钮
              Wrap(
                spacing: UiTokens.spaceS,
                runSpacing: UiTokens.spaceXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatPill(text: '回复 ${article.reply}', dark: isDark),
                  _StatPill(text: '查看 ${article.view}', dark: isDark),
                  if (article.origin.isNotEmpty)
                    _StatPill(text: article.origin, dark: isDark),
                  _StatPill(text: article.author, dark: isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 浅色胶囊标签
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}

/// 浅灰胶囊数据按钮
class _StatPill extends StatelessWidget {
  const _StatPill({required this.text, required this.dark});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: dark ? const Color(0xFF9E9E9E) : UiTokens.textGray,
        ),
      ),
    );
  }
}