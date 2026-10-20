import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/account/account_manager.dart';
import '../../core/account/user_data_repo.dart';
import '../../core/config/website_constants.dart';
import '../../data/repository/login_repository.dart';
import '../../theme/ui_tokens.dart';
import '../article/article_page.dart';
import '../favorite/favorite_page.dart';
import '../follow/follow_page.dart';
import '../history/history_page.dart';
import '../login/login_page.dart';
import '../message/message_page.dart';
import '../settings/settings_page.dart';

/// 我的页（对应 MeFragment）
class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  @override
  void initState() {
    super.initState();
    _refreshUserInfo();
  }

  /// 已登录但用户信息为空时主动拉取（登录后同步/重启后恢复）
  Future<void> _refreshUserInfo() async {
    if (!AccountManager.instance.isLoggedIn) return;
    final info = await LoginRepository.instance.requestUserInfo();
    if (info.isValid) {
      UserDataRepo.updateUserInfo(info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountManager>(
      builder: (context, am, _) {
        final loggedIn = am.isLoggedIn;
        return RefreshIndicator(
          onRefresh: _refreshUserInfo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(UiTokens.spaceM),
            children: [
              _UserCard(loggedIn: loggedIn),
              const SizedBox(height: UiTokens.spaceM),
              if (!loggedIn)
                _LoginEntryCard()
              else ...[
                _FeatureGrid(),
                const SizedBox(height: UiTokens.spaceM),
                _NotificationCard(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final am = context.watch<AccountManager>();
    final info = am.userInfo;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (info.avatarUrl != null && info.avatarUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(UiTokens.cornerS),
                    child: CachedNetworkImage(
                      imageUrl: info.avatarUrl!,
                      httpHeaders: const {
                        'Referer': WebsiteConstants.serverBaseUrl,
                        'User-Agent': WebsiteConstants.desktopUserAgent,
                      },
                      width: UiTokens.sizeAvatarLarge,
                      height: UiTokens.sizeAvatarLarge,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(Icons.person,
                          size: UiTokens.sizeAvatarLarge,
                          color: scheme.onSurfaceVariant),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: UiTokens.sizeAvatarLarge / 2,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person, color: scheme.onPrimaryContainer, size: 32),
                  ),
                const SizedBox(width: UiTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.userName ?? '游客',
                        style: TextStyle(
                          fontSize: UiTokens.fontBody,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.groupInfo ?? '',
                        style: TextStyle(
                          fontSize: UiTokens.fontTag,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
              ],
            ),
            if (loggedIn) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(label: '吾爱币', value: info.wuaiCoin ?? '-'),
                  _Metric(label: '积分', value: info.credit ?? '-'),
                  _Metric(label: '采纳率', value: info.answerRate ?? '-'),
                  _Metric(label: '热心值', value: info.enthusiasticValue ?? '-'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: UiTokens.fontAux,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LoginEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.spaceM),
        child: Column(
          children: [
            Text(
              '登录吾爱破解',
              style: TextStyle(
                fontSize: UiTokens.fontBody,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: UiTokens.spaceXs),
            Text(
              '登录后可使用收藏、关注、签到等功能',
              style: TextStyle(fontSize: UiTokens.fontAux, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: UiTokens.spaceM),
            FilledButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
                if (ok == true) {
                  // 登录态由 AccountManager 通知刷新
                }
              },
              child: const Text('登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: UiTokens.spaceM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FeatureItem(
              icon: Icons.star_outline,
              label: '我的收藏',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritePage()),
              ),
            ),
            _FeatureItem(
              icon: Icons.article_outlined,
              label: '我的帖子',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticlePage(
                    url: 'https://www.52pojie.cn/${WebsiteConstants.myArticlesQuery}',
                  ),
                ),
              ),
            ),
            _FeatureItem(
              icon: Icons.people_outline,
              label: '我的收听',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FollowPage()),
              ),
            ),
            _FeatureItem(
              icon: Icons.history,
              label: '阅读记录',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UiTokens.cornerS),
      child: Padding(
        padding: const EdgeInsets.all(UiTokens.spaceS),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 26),
            const SizedBox(height: UiTokens.spaceS),
            Text(
              label,
              style: TextStyle(fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.notifications_none, color: scheme.primary),
        title: const Text('我的信息'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationListPage()),
        ),
      ),
    );
  }
}
