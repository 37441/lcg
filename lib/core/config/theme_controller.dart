import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题预设（主题色 + 浅色容器）
class ThemePreset {
  const ThemePreset(this.name, this.primary, this.container);

  final String name;
  final Color primary;
  final Color container;
}

/// 外观设置：主题色 / 明暗模式 / 字体缩放（持久化）
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const presets = <ThemePreset>[
    ThemePreset('经典蓝', Color(0xFF2563EB), Color(0xFFDBEAFE)),
    ThemePreset('薄荷绿', Color(0xFF10B981), Color(0xFFD1FAE5)),
    ThemePreset('紫罗兰', Color(0xFF7C3AED), Color(0xFFEDE9FE)),
    ThemePreset('日落橙', Color(0xFFF97316), Color(0xFFFFEDD5)),
    ThemePreset('玫瑰红', Color(0xFFE11D48), Color(0xFFFFE4E6)),
  ];

  static const fontScaleOptions = <double>[0.9, 1.0, 1.15, 1.25];

  static const _kPreset = 'theme_preset_index';
  static const _kMode = 'theme_mode';
  static const _kFontScale = 'font_scale';

  int _presetIndex = 0;
  ThemeMode _mode = ThemeMode.system;
  double _fontScale = 1.0;
  SharedPreferences? _prefs;

  ThemePreset get preset => presets[_presetIndex];
  int get presetIndex => _presetIndex;
  ThemeMode get mode => _mode;
  double get fontScale => _fontScale;

  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final self = instance;
    self._prefs = p;
    self._presetIndex = (p.getInt(_kPreset) ?? 0).clamp(0, presets.length - 1);
    switch (p.getInt(_kMode) ?? 0) {
      case 1:
        self._mode = ThemeMode.light;
        break;
      case 2:
        self._mode = ThemeMode.dark;
        break;
      default:
        self._mode = ThemeMode.system;
    }
    self._fontScale = p.getDouble(_kFontScale) ?? 1.0;
  }

  void setPreset(int index) {
    _presetIndex = index.clamp(0, presets.length - 1);
    _prefs?.setInt(_kPreset, _presetIndex);
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    final v = mode == ThemeMode.light ? 1 : (mode == ThemeMode.dark ? 2 : 0);
    _prefs?.setInt(_kMode, v);
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.85, 1.25);
    _prefs?.setDouble(_kFontScale, _fontScale);
    notifyListeners();
  }
}