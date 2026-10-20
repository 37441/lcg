import 'package:flutter/foundation.dart';

/// 轻量诊断日志（内存环形缓冲，供「诊断日志」页查看）
class AppLog {
  AppLog._();

  static final AppLog instance = AppLog._();
  static const _max = 500;

  final List<String> _lines = [];
  final ValueNotifier<int> version = ValueNotifier(0);

  List<String> get lines => List.unmodifiable(_lines);

  void add(String tag, String message) {
    final now = DateTime.now();
    final ts = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _lines.add('$ts [$tag] $message');
    if (_lines.length > _max) {
      _lines.removeAt(0);
    }
    version.value++;
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  void clear() {
    _lines.clear();
    version.value++;
  }
}

/// 快捷方法
void logD(String tag, String message) => AppLog.instance.add(tag, message);