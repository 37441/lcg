import 'package:intl/intl.dart';

/// 时间工具 —— 对应原生 TimeUtils.kt
class TimeUtils {
  TimeUtils._();

  static final _fmt = DateFormat('yyyy-MM-dd HH:mm');
  static final _fmtShort = DateFormat('yyyy-MM-dd');

  /// "2020-02-09 16:22" → 毫秒时间戳，解析失败返回当前时间
  static int toTimeStamp(String date) {
    try {
      return _fmt.parse(date).millisecondsSinceEpoch;
    } catch (_) {
      try {
        return DateTime.parse(date).millisecondsSinceEpoch;
      } catch (_) {
        return DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  /// 相对时间：刚刚 / n分钟前 / n小时前 / 昨天 / n天前 / 具体日期
  static String relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final day = DateTime(time.year, time.month, time.day);
    if (day == yesterday) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return _fmtShort.format(time);
  }

  static String relativeTimeFromTs(int ts) => relativeTime(DateTime.fromMillisecondsSinceEpoch(ts));
}
