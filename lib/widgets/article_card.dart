import 'package:flutter/material.dart';

import '../data/models/article.dart';
import '../theme/ui_tokens.dart';

/// 文章卡片 —— 参考图布局：标题 + 作者/板块胶囊/时间 + 底部三等宽胶囊数据
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
              // 标题
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: UiTokens.fontBody,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              // 作者 + 板块胶囊 + 时间
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 14, color: textGray),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      article.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  if (article.origin.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: UiTokens.mintGreenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.origin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: UiTokens.mintGreen),
                        ),
                      ),
                    ),
                  ],
                  if (article.isRecommended) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '推荐',
                        style: TextStyle(fontSize: 11, color: textGray),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (article.helpCoin != 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.helpCoin == -1 ? '已解决' : '悬赏',
                        style: TextStyle(fontSize: 11, color: textGray),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // 底部三等宽胶囊数据按钮
              Row(
                children: [
                  Expanded(child: _StatPill(icon: Icons.chat_bubble_outline, text: '回复 ${article.reply}', dark: isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatPill(icon: Icons.visibility_outlined, text: '查看 ${article.view}', dark: isDark)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatPill(icon: Icons.thumb_up_outlined, text: article.date, dark: isDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 浅灰胶囊数据按钮（图标 + 文字）
class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.text, required this.dark});

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final gray = dark ? const Color(0xFF9E9E9E) : UiTokens.textGray;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: gray),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: gray),
            ),
          ),
        ],
      ),
    );
  }
}