import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '关于',
      ),
      body: Container(
        color: theme.background,
        child: ListView(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.liujinAccent,
                      AppColors.liujinPrimary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.liujinPrimary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_book,
                  size: 56,
                  color: AppColors.liujinBackground,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                AppInfo.appName,
                style: TextStyle(
                  color: theme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '版本 ${AppInfo.version}',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const GoldDivider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '开发者',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppInfo.developer,
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const GoldDivider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '简介',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppInfo.aboutDesc,
                    style: TextStyle(
                      color: theme.onBackground,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const GoldDivider(),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2024 ${AppInfo.appName}',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
