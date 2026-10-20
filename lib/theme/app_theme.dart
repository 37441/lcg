import 'package:flutter/material.dart';

import '../core/config/theme_controller.dart';
import 'ui_tokens.dart';

/// App 主题：支持主题色预设 + 明暗模式
class AppTheme {
  AppTheme._();

  /// 默认预设（兼容旧调用）
  static ThemeData get light => build(ThemeController.presets.first, Brightness.light);

  static ThemeData get dark => build(ThemeController.presets.first, Brightness.dark);

  static ThemeData build(ThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = preset.primary;
    final primaryContainer = isDark
        ? Color.alphaBlend(primary.withValues(alpha: 0.3), const Color(0xFF1E1E1E))
        : preset.container;
    final onPrimaryContainer = isDark ? preset.container : preset.primary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: UiTokens.onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: primary,
      onSecondary: UiTokens.onPrimary,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: onPrimaryContainer,
      error: UiTokens.error,
      onError: UiTokens.onPrimary,
      surface: isDark ? UiTokens.surfaceDark : UiTokens.surface,
      onSurface: isDark ? UiTokens.textPrimaryDark : UiTokens.textPrimary,
      surfaceContainerHighest:
          isDark ? UiTokens.surfaceVariantDark : UiTokens.surfaceVariant,
      onSurfaceVariant:
          isDark ? UiTokens.textSecondaryDark : UiTokens.textSecondary,
      outline: isDark ? UiTokens.dividerDark : UiTokens.divider,
      outlineVariant: isDark ? UiTokens.dividerDark : UiTokens.divider,
      scrim: UiTokens.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? UiTokens.backgroundDark : UiTokens.communityBg,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? UiTokens.surfaceDark : Colors.white,
        foregroundColor: isDark ? colorScheme.onSurface : UiTokens.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: UiTokens.fontBody,
          fontWeight: FontWeight.w600,
          color: isDark ? colorScheme.onSurface : UiTokens.textDark,
        ),
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : UiTokens.textDark,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: UiTokens.tabUnselected,
        selectedLabelStyle:
            const TextStyle(fontSize: UiTokens.fontTag, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: UiTokens.fontTag),
      ),
      cardTheme: CardThemeData(
        color: isDark ? UiTokens.surfaceDark : Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: UiTokens.spaceM, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiTokens.cornerM),
          side: BorderSide(
            color: isDark ? UiTokens.dividerDark : const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: UiTokens.fontAux,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: UiTokens.fontTitle,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: UiTokens.fontBody,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: UiTokens.fontAux,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: UiTokens.fontTag,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}