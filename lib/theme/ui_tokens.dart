import 'package:flutter/material.dart';

/// UI Token —— 对应原生 framework ui_tokens.xml（语义命名，禁止硬编码）
class UiTokens {
  UiTokens._();

  // ---- 品牌色 ----
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E40AF);

  // ---- 背景层级 ----
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F0);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFFC0C0C0);
  static const Color textLink = Color(0xFF2563EB);

  // ---- 线 & 状态 ----
  static const Color divider = Color(0xFFEEEEEE);
  static const Color scrim = Color(0x50000000);

  // ---- 语义色 ----
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF00A862);
  static const Color warning = Color(0xFFFF7D27);

  // ---- 选中态 ----
  static const Color tabSelected = Color(0xFF2563EB);
  static const Color tabUnselected = Color(0xFF9A9A9A);
  static const Color badge = Color(0xFFDC2626);

  // ---- 深色模式覆盖 ----
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF1F1F1F);
  static const Color textPrimaryDark = Color(0xFFE6E6E6);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  static const Color dividerDark = Color(0xFF2E2E2E);
  static const Color primaryContainerDark = Color(0xFF1E3A8A);
  static const Color onPrimaryContainerDark = Color(0xFFDBEAFE);
  static const Color tabSelectedDark = Color(0xFF6D9DF2);

  // ---- 字号（四档制）----
  static const double fontTitle = 20;
  static const double fontBody = 16;
  static const double fontAux = 14;
  static const double fontTag = 12;

  // ---- 圆角（五档制）----
  static const double cornerXs = 8;
  static const double cornerS = 12;
  static const double cornerM = 16;
  static const double cornerL = 20;
  static const double cornerXl = 30;

  // ---- 间距（8dp 网格）----
  static const double spaceXs = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;

  // ---- 组件尺寸 ----
  static const double sizeAvatar = 40;
  static const double sizeAvatarLarge = 56;
  static const double sizeBottomNav = 56;
  static const double sizeTabIcon = 24;
  static const double sizeButton = 48;
  static const double sizeInput = 48;
  static const double sizeListRow = 64;
}
