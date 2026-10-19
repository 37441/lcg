import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/ui_tokens.dart';

/// 关于页（对应 AboutFragment）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('『关于应用』')),
      body: ListView(
        children: [
          const SizedBox(height: UiTokens.spaceL),
          CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primary,
            child: const Icon(Icons.forum, color: Colors.white, size: 36),
          ),
          const SizedBox(height: UiTokens.spaceM),
          const Center(
            child: Text('吾爱破解', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: UiTokens.spaceXs),
          Center(
            child: Text(
              '开源吾爱破解论坛APP · Flutter 重写版',
              style: TextStyle(fontSize: UiTokens.fontTag, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: UiTokens.spaceL),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Github源码地址'),
            subtitle: const Text('https://github.com/fabricezhang/lcg/'),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/fabricezhang/lcg/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('问题反馈邮箱'),
            subtitle: const Text('fabrice@163.com'),
            onTap: () => launchUrl(
              Uri.parse('mailto:fabrice@163.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}