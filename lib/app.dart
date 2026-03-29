import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/theme_notifier.dart';
import 'ui/bookshelf/bookshelf_screen.dart';
import 'ui/router/app_router.dart';

class PeiyuBookhouseApp extends ConsumerWidget {
  const PeiyuBookhouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: '佩宇书屋',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildMaterialTheme(themeData),
      darkTheme: AppTheme.buildMaterialTheme(AppTheme.dark),
      themeMode: themeData.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      onGenerateRoute: AppRouter.generateRoute,
      home: const BookshelfScreen(),
    );
  }
}
