import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/account/account_manager.dart';
import 'core/config/theme_controller.dart';
import 'pages/article/article_page.dart';
import 'pages/splash/splash_page.dart';
import 'theme/app_theme.dart';

class LcgApp extends StatelessWidget {
  const LcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AccountManager.instance),
        ChangeNotifierProvider.value(value: ThemeController.instance),
      ],
      child: Consumer<ThemeController>(
        builder: (context, tc, _) => MaterialApp(
          title: '吾爱破解',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(tc.preset, Brightness.light),
          darkTheme: AppTheme.build(tc.preset, Brightness.dark),
          themeMode: tc.mode,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final media = MediaQuery.of(context);
            // 字体缩放限制在 0.9~1.25，避免字号过大撑破布局
            final scale = tc.fontScale.clamp(0.9, 1.25);
            return AnnotatedRegion<SystemUiOverlayStyle>(
              // 状态栏 / 底部导航栏颜色跟随主题明暗
              value: isDark
                  ? const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                      systemNavigationBarColor: Color(0xFF121212),
                      systemNavigationBarIconBrightness: Brightness.light,
                      systemNavigationBarDividerColor: Colors.transparent,
                    )
                  : const SystemUiOverlayStyle(
                      statusBarColor: Colors.white,
                      statusBarIconBrightness: Brightness.dark,
                      statusBarBrightness: Brightness.light,
                      systemNavigationBarColor: Colors.white,
                      systemNavigationBarIconBrightness: Brightness.dark,
                      systemNavigationBarDividerColor: Colors.transparent,
                    ),
              child: MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(scale)),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/article') {
              return MaterialPageRoute(
                builder: (_) => ArticlePage(url: settings.arguments as String),
              );
            }
            return null;
          },
          home: const SplashPage(),
        ),
      ),
    );
  }
}