import 'package:html/parser.dart' as html_parser;

import '../../core/account/user_info.dart';
import '../../core/network/api_client.dart';
import '../models/misc_models.dart';

/// 用户额外信息（对应 ExtraUserInfo）
class ExtraUserInfo {
  ExtraUserInfo({required this.name, required this.value});

  final String name;
  final String value;
}

/// 页面解析 —— 对应原生 DocParser.kt（用户信息/通知/formhash/反爬/个人页）
class DocParser {
  DocParser._();

  /// 解析个人主页 dl/dt 信息
  static List<ExtraUserInfo> parseExtraUserInfo(String content) {
    final doc = html_parser.parse(content);
    final dts = doc.querySelectorAll('dt');
    final dds = doc.querySelectorAll('dd');
    final list = <ExtraUserInfo>[];
    for (var i = 0; i < dts.length && i < dds.length; i++) {
      list.add(ExtraUserInfo(name: dts[i].text, value: dds[i].text));
    }
    return list;
  }

  /// 解析用户信息；未登录/反爬时抛 [AntiScrapingException] 或返回默认值（对应 parseUserInfo）
  static UserInfo parseUserInfo(String html) {
    final doc = html_parser.parse(html);
    final userName = doc.querySelector('h2.mt')?.text;
    if (userName == null || userName.isEmpty) {
      final message = doc.getElementById('messagetext')?.text ?? '';
      if (message.isEmpty) {
        throw AntiScrapingException();
      }
      throw BlockException(message);
    }
    if (userName == '登录或注册') {
      return UserInfo.defaultUserInfo();
    }

    final avatar = doc.querySelector('div.avt > a > img')?.attributes['src'];
    final groupInfo = doc.getElementById('g_upmine')?.text;
    final infoList = doc.getElementById('psts')?.querySelector('ul.pf_l')?.children ?? [];
    String? signInState;
    for (final img in doc.querySelectorAll('img.qq_bind')) {
      final src = img.attributes['src'] ?? '';
      if (!src.contains('qq')) {
        signInState = src;
        break;
      }
    }
    return UserInfo(
      userName: userName,
      avatarUrl: avatar,
      groupInfo: groupInfo,
      wuaiCoin: infoList.length > 3 ? infoList[3].text : null,
      credit: infoList.length > 1 ? infoList[1].text : null,
      answerRate: infoList.length > 6 ? infoList[6].text : null,
      enthusiasticValue: infoList.length > 7 ? infoList[7].text : null,
      signInStateUrl: signInState,
    );
  }

  /// 通知计数（对应 parseNotificationInfo + checkMessages）
  static NotificationInfo parseNotificationInfo(String html) {
    final doc = html_parser.parse(html);
    var message = 0;
    var follower = 0;
    var myPost = 0;
    var systemNotifs = 0;
    final menu = doc.getElementById('myprompt_menu');
    menu?.querySelectorAll('li').forEach((li) {
      try {
        final span = li.querySelector('a > span');
        final v = span?.text ?? '';
        final n = int.tryParse(v);
        if (n == null || n < 1) return;
        final url = li.querySelector('a')?.attributes['href'] ?? '';
        if (url.contains('mypost')) {
          myPost++;
        } else if (url.contains('follower')) {
          follower++;
        } else if (url.contains('pm')) {
          message++;
        } else if (url.contains('system')) {
          systemNotifs++;
        }
      } catch (_) {}
    });
    return NotificationInfo(
      message: message,
      follower: follower,
      myPost: myPost,
      systemNotifs: systemNotifs,
    );
  }

  /// 提取 formhash
  static String? extractFormHash(String html) {
    return html_parser
        .parse(html)
        .querySelector('input[name="formhash"]')
        ?.attributes['value'];
  }
}