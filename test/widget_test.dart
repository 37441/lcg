import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcg/theme/app_theme.dart';
import 'package:lcg/theme/ui_tokens.dart';

void main() {
  testWidgets('主题能正常构建浅色/深色 ThemeData', (tester) async {
    final light = AppTheme.light;
    final dark = AppTheme.dark;
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, UiTokens.primary);
    expect(dark.colorScheme.surface, UiTokens.surfaceDark);
  });

  testWidgets('MaterialApp 包裹基本页面可渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Text('吾爱破解')),
      ),
    );
    expect(find.text('吾爱破解'), findsOneWidget);
  });
}