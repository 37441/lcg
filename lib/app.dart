import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/account/account_manager.dart';
import 'pages/article/article_page.dart';
import 'pages/main/main_shell.dart';
import 'theme/app_theme.dart';

class LcgApp extends StatelessWidget {
  const LcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AccountManager.instance),
      ],
      child: MaterialApp(
        title: '吾爱破解',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        onGenerateRoute: (settings) {
          if (settings.name == '/article') {
            return MaterialPageRoute(
              builder: (_) => ArticlePage(url: settings.arguments as String),
            );
          }
          return null;
        },
        home: const MainShell(),
      ),
    );
  }
}