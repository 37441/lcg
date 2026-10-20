import 'package:flutter/material.dart';

import '../../theme/ui_tokens.dart';
import '../../widgets/article_list_view.dart';
import 'rank_page.dart';

/// 社区页（板块导读）—— 薄荷绿极简卡片风格
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

/// 52pojie 真实板块（名称与 fid 均取自网站实测）
class _Section {
  const _Section(this.name, this.fid, this.icon, this.color);

  final String name;
  final int fid;
  final IconData icon;
  final Color color;
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const _sections = <_Section>[
    _Section('原创发布区', 2, Icons.edit_outlined, Color(0xFF10B981)),
    _Section('精品软件区', 16, Icons.apps, Color(0xFF60A5FA)),
    _Section('逆向资源区', 4, Icons.alt_route, Color(0xFFF472B6)),
    _Section('脱壳破解区', 5, Icons.vpn_key_outlined, Color(0xFFFBBF24)),
    _Section('移动安全区', 65, Icons.phone_android, Color(0xFFA78BFA)),
    _Section('编程语言区', 24, Icons.code, Color(0xFFFB923C)),
    _Section('悬赏问答区', 8, Icons.help_outline, Color(0xFF2DD4BF)),
    _Section('安全工具区', 41, Icons.build_outlined, Color(0xFFFB7185)),
    _Section('病毒分析区', 32, Icons.bug_report_outlined, Color(0xFF34D399)),
    _Section('病毒救援区', 50, Icons.healing, Color(0xFF38BDF8)),
    _Section('动画发布区', 6, Icons.movie_outlined, Color(0xFFC084FC)),
    _Section('福利经验区', 66, Icons.card_giftcard, Color(0xFFFCD34D)),
    _Section('水漫金山区', 10, Icons.water_drop_outlined, Color(0xFF94A3B8)),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UiTokens.communityBg,
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(UiTokens.spaceM, 12, UiTokens.spaceM, 8),
            child: Row(
              children: [
                const Text(
                  '社区',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: UiTokens.textDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  UiTokens.spaceM, 0, UiTokens.spaceM, UiTokens.spaceM),
              children: [
                // 板块导读卡片
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(UiTokens.spaceM),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: UiTokens.mintGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '板块导读',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: UiTokens.textDark,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_sections.length} 个板块',
                              style: const TextStyle(
                                  fontSize: 11, color: UiTokens.textGray),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final s in _sections)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openSection(s),
                          child: SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(s.icon, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: UiTokens.textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right,
                                    size: 18, color: Color(0xFFBBBBBB)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 今日热榜入口
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RankPage()),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(UiTokens.spaceM),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: UiTokens.mintGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '今日热榜',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: UiTokens.textDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: Color(0xFFBBBBBB)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSection(_Section s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SectionArticlesPage(
          title: s.name,
          query: 'forum-${s.fid}-1.html',
        ),
      ),
    );
  }
}

class _SectionArticlesPage extends StatelessWidget {
  const _SectionArticlesPage({required this.title, required this.query});

  final String title;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ArticleListView(query: query),
    );
  }
}