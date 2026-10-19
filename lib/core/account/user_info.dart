/// 用户信息 —— 对应原生 UserInfo.kt
class UserInfo {
  UserInfo({
    this.userName,
    this.groupInfo,
    this.avatarUrl,
    this.wuaiCoin,
    this.credit,
    this.answerRate,
    this.enthusiasticValue,
    this.signInStateUrl,
  });

  final String? userName;
  final String? groupInfo;
  final String? avatarUrl;
  final String? wuaiCoin;
  final String? credit;
  final String? answerRate;
  final String? enthusiasticValue;
  final String? signInStateUrl;

  bool get isValid => userName != null && userName!.isNotEmpty;

  factory UserInfo.defaultUserInfo() => UserInfo(
        userName: '游客',
        groupInfo: '游客',
        avatarUrl: '',
        wuaiCoin: '-',
        credit: '-',
        answerRate: '-',
        enthusiasticValue: '-',
        signInStateUrl: null,
      );

  @override
  bool operator ==(Object other) =>
      other is UserInfo &&
      userName == other.userName &&
      avatarUrl == other.avatarUrl &&
      groupInfo == other.groupInfo &&
      wuaiCoin == other.wuaiCoin &&
      credit == other.credit &&
      signInStateUrl == other.signInStateUrl;

  @override
  int get hashCode =>
      Object.hash(userName, avatarUrl, groupInfo, wuaiCoin, credit, signInStateUrl);
}