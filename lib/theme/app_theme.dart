import 'package:flutter/material.dart';

import 'ui_tokens.dart';

/// App 主题：浅色 + 深色，全部取 UiTokens，组件通过主题引用
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: UiTokens.primary,
      onPrimary: UiTokens.onPrimary,
      primaryContainer: isDark ? UiTokens.primaryContainerDark : UiTokens.primaryContainer,
      onPrimaryContainer:
          isDark ? UiTokens.onPrimaryContainerDark : UiTokens.onPrimaryContainer,
      secondary: UiTokens.primary,
      onSecondary: UiTokens.onPrimary,
      secondaryContainer:
          isDark ? UiTokens.primaryContainerDark : UiTokens.primaryContainer,
      onSecondaryContainer:
          isDark ? UiTokens.onPrimaryContainerDark : UiTokens.onPrimaryContainer,
      error: UiTokens.error,
      onError: UiTokens.onPrimary,
      surface: isDark ? UiTokens.surfaceDark : UiTokens.surface,
      onSurface:
          isDark ? UiTokens.textPrimaryDark : UiTokens.textPrimary,
      surfaceContainerHighest:
          isDark ? UiTokens.surfaceVariantDark : UiTokens.surfaceVariant,
      onSurfaceVariant:
          isDark ? UiTokens.textSecondaryDark : UiTokens.textSecondary,
      outline: isDark ? UiTokens.dividerDark : UiTokens.divider,
      outlineVariant: isDark ? UiTokens.dividerDark : UiTokens.divider,
      scrim: UiTokens.scrim,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? UiTokens.backgroundDark : UiTokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: UiTokens.fontBody,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: UiTokens.tabUnselected,
        selectedLabelStyle:
            const TextStyle(fontSize: UiTokens.fontTag, fontWeight: FontWeight.w500),
        unselectedLabelStyle:
            const TextStyle(fontSize: UiTokens.fontTag),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiTokens.cornerM),
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
    return base;
  }
}