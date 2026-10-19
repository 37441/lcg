/// 发现页模型 —— 论坛导航 + 排行榜
class ForumNavigationModel {
  ForumNavigationModel({required this.title, required this.url});

  final String title;
  final String url;
}

class RankListModel {
  RankListModel({required this.list, this.time = ''});

  final List<RankModel> list;
  final String time;
}

class RankModel {
  RankModel({
    required this.index,
    required this.title,
    required this.url,
    this.forum = '',
    this.authorName = '',
    this.authorUrl = '',
    this.date = '',
    required this.type,
    this.num = 0,
  });

  final int index;
  final String title;
  final String url;
  final String forum;
  final String authorName;
  final String authorUrl;
  final String date;
  final RankType type;
  final int num;
}

enum RankType {
  view('views'),
  reply('replies'),
  heat('heat'),
  favorite('favtimes'),
  share('sharetimes');

  const RankType(this.value);
  final String value;
}

enum DateType {
  today('today'),
  all('all'),
  month('thismonth'),
  week('thisweek');

  const DateType(this.value);
  final String value;
}