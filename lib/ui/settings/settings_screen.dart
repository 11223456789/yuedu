import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'about_screen.dart';
import 'clone_tts_settings_screen.dart';
import '../book_source/book_source_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '设置',
      ),
      body: Container(
        color: theme.background,
        child: ListView(
          children: [
            _buildSectionHeader('外观', theme),
            _buildThemeSetting(ref, theme),
            const GoldDivider(),
            _buildSectionHeader('阅读', theme),
            _buildSettingItem(
              icon: Icons.font_download,
              title: '字体设置',
              subtitle: '选择字体、字号、行距',
              theme: theme,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.palette,
              title: '阅读配色',
              subtitle: '选择背景和文字颜色',
              theme: theme,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.article,
              title: '翻页模式',
              subtitle: PageTurnMode.slide.displayName,
              theme: theme,
              onTap: () {},
            ),
            const GoldDivider(),
            _buildSectionHeader('网络', theme),
            _buildSettingItem(
              icon: Icons.cloud,
              title: 'WebDAV 备份',
              subtitle: '备份和恢复数据',
              theme: theme,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.language,
              title: 'Web 服务',
              subtitle: '局域网书源编辑',
              theme: theme,
              onTap: () {},
            ),
            const GoldDivider(),
            _buildSectionHeader('朗读', theme),
            _buildSettingItem(
              icon: Icons.record_voice_over,
              title: 'CloneTTS 设置',
              subtitle: '快速启用 CloneTTS 本地 TTS',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CloneTtsSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.volume_up,
              title: '朗读设置',
              subtitle: '系统 TTS、语速、音调',
              theme: theme,
              onTap: () {},
            ),
            const GoldDivider(),
            _buildSectionHeader('书源', theme),
            _buildSettingItem(
              icon: Icons.source,
              title: '书源管理',
              subtitle: '添加、编辑、校验书源',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookSourceListScreen(),
                  ),
                );
              },
            ),
            const GoldDivider(),
            _buildSectionHeader('其他', theme),
            _buildSettingItem(
              icon: Icons.bookmark,
              title: '书签管理',
              subtitle: '查看所有书签',
              theme: theme,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.history,
              title: '阅读记录',
              subtitle: '查看阅读统计',
              theme: theme,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.info,
              title: '关于',
              subtitle: AppInfo.appName,
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: theme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSetting(WidgetRef ref, AppThemeData theme) {
    return Column(
      children: ThemeType.values.map((type) {
        if (type == ThemeType.system) return const SizedBox.shrink();
        final isSelected = theme.themeType == type;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setTheme(type);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? theme.primary : theme.divider,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getThemeBgColor(type),
                      border: Border.all(
                        color: _getThemePrimaryColor(type),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getThemeBgColor(ThemeType type) {
    switch (type) {
      case ThemeType.liujin:
        return AppColors.liujinBackground;
      case ThemeType.light:
        return AppColors.lightBackground;
      case ThemeType.dark:
        return AppColors.darkBackground;
      case ThemeType.eink:
        return AppColors.einkBackground;
      case ThemeType.system:
        return AppColors.liujinBackground;
    }
  }

  Color _getThemePrimaryColor(ThemeType type) {
    switch (type) {
      case ThemeType.liujin:
        return AppColors.liujinPrimary;
      case ThemeType.light:
        return AppColors.lightPrimary;
      case ThemeType.dark:
        return AppColors.darkPrimary;
      case ThemeType.eink:
        return AppColors.einkPrimary;
      case ThemeType.system:
        return AppColors.liujinPrimary;
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required AppThemeData theme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.subText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
