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
import 'read_record_screen.dart';
import '../book_source/book_source_list_screen.dart';
import '../rss/rss_source_list_screen.dart';
import 'replace_rule_screen.dart';
import '../reader/bookmark_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoDarkMode = false;
  TimeOfDay _darkModeStartTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _darkModeEndTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadAutoDarkModeSettings();
  }

  Future<void> _loadAutoDarkModeSettings() async {
    // TODO: 从本地存储加载设置
  }

  Future<void> _saveAutoDarkMode(bool value) async {
    // TODO: 保存到本地存储
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _darkModeStartTime : _darkModeEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _darkModeStartTime = picked;
        } else {
          _darkModeEndTime = picked;
        }
      });
    }
  }

  void _checkAndApplyDarkMode() {
    final now = TimeOfDay.now();
    final isDarkMode = _isTimeInRange(now, _darkModeStartTime, _darkModeEndTime);
    // TODO: 应用夜间模式
  }

  bool _isTimeInRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // 跨天的情况，比如 22:00 到 06:00
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () => _showFontSettingsDialog(context, ref, theme),
            ),
            _buildSettingItem(
              icon: Icons.palette,
              title: '阅读配色',
              subtitle: '选择背景和文字颜色',
              theme: theme,
              onTap: () => _showReadingThemeDialog(context, ref, theme),
            ),
            _buildSettingItem(
              icon: Icons.article,
              title: '翻页模式',
              subtitle: PageTurnMode.slide.displayName,
              theme: theme,
              onTap: () => _showPageTurnModeDialog(context, ref, theme),
            ),
            _buildSettingItem(
              icon: Icons.brightness_auto,
              title: '自动夜间模式',
              subtitle: '根据时间自动切换夜间主题',
              theme: theme,
              onTap: () {},
              trailing: Switch(
                value: _autoDarkMode,
                onChanged: (value) {
                  setState(() {
                    _autoDarkMode = value;
                  });
                  _saveAutoDarkMode(value);
                  if (value) {
                    _checkAndApplyDarkMode();
                  }
                },
                activeColor: theme.primary,
              ),
            ),
            if (_autoDarkMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '开始时间',
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, true),
                      child: Text(
                        '${_darkModeStartTime.hour.toString().padLeft(2, '0')}:${_darkModeStartTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: theme.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '结束时间',
                      style: TextStyle(
                        color: theme.onBackground,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectTime(context, false),
                      child: Text(
                        '${_darkModeEndTime.hour.toString().padLeft(2, '0')}:${_darkModeEndTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: theme.primary),
                      ),
                    ),
                  ],
                ),
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
              onTap: () => _showTTSSettingsDialog(context, ref, theme),
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
            _buildSectionHeader('RSS订阅', theme),
            _buildSettingItem(
              icon: Icons.rss_feed,
              title: 'RSS订阅管理',
              subtitle: '管理RSS订阅源',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RssSourceListScreen(),
                  ),
                );
              },
            ),
            const GoldDivider(),
            _buildSectionHeader('净化', theme),
            _buildSettingItem(
              icon: Icons.find_replace,
              title: '替换规则',
              subtitle: '内容替换净化',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReplaceRuleScreen(),
                  ),
                );
              },
            ),
            const GoldDivider(),
            _buildSectionHeader('数据管理', theme),
            _buildSettingItem(
              icon: Icons.bookmark,
              title: '书签管理',
              subtitle: '查看所有书签',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookmarkScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.history,
              title: '阅读记录',
              subtitle: '查看阅读统计',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadRecordScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.storage,
              title: '缓存管理',
              subtitle: '清理书籍缓存',
              theme: theme,
              onTap: () => _showCacheManagementDialog(context, ref, theme),
            ),
            _buildSettingItem(
              icon: Icons.backup,
              title: '备份与恢复',
              subtitle: '导出/导入应用数据',
              theme: theme,
              onTap: () => _showBackupDialog(context, ref, theme),
            ),
            const GoldDivider(),
            _buildSectionHeader('其他', theme),
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
    Widget? trailing,
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
              if (trailing != null)
                trailing
              else
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

  void _showFontSettingsDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    double fontSize = 18;
    double lineHeight = 1.6;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            '字体设置',
            style: TextStyle(color: theme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.format_size, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '字体大小',
                      style: TextStyle(color: theme.onSurface),
                    ),
                  ),
                  Text(
                    '${fontSize.toInt()}sp',
                    style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: fontSize,
                min: 12,
                max: 32,
                divisions: 10,
                activeColor: theme.primary,
                thumbColor: theme.primary,
                onChanged: (value) {
                  setState(() {
                    fontSize = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.format_line_spacing, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '行间距',
                      style: TextStyle(color: theme.onSurface),
                    ),
                  ),
                  Text(
                    '${lineHeight.toStringAsFixed(1)}x',
                    style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: lineHeight,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                activeColor: theme.primary,
                thumbColor: theme.primary,
                onChanged: (value) {
                  setState(() {
                    lineHeight = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.font_download, color: theme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '字体样式',
                      style: TextStyle(color: theme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['系统默认', '宋体', '黑体', '楷体', '仿宋'].map((font) {
                  return ChoiceChip(
                    label: Text(font),
                    selected: font == '系统默认',
                    onSelected: (selected) {},
                    selectedColor: theme.primary,
                    labelStyle: TextStyle(
                      color: font == '系统默认' ? theme.background : theme.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: theme.subText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('字体设置已保存')),
                );
              },
              child: Text(
                '确定',
                style: TextStyle(color: theme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingThemeDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final themes = [
      {'name': '深色', 'bg': AppColors.darkBackground, 'text': AppColors.textPrimary},
      {'name': '浅色', 'bg': AppColors.lightBackground, 'text': AppColors.lightTextPrimary},
      {'name': '护眼', 'bg': const Color(0xFFE8DCC8), 'text': const Color(0xFF3D3D3D)},
      {'name': '羊皮纸', 'bg': const Color(0xFFF5E6C8), 'text': const Color(0xFF5C4B37)},
      {'name': '夜间', 'bg': const Color(0xFF0D0D0D), 'text': const Color(0xFFB0B0B0)},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '阅读配色',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((t) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t['bg'] as Color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.divider),
                ),
                child: Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      color: t['text'] as Color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                t['name'] as String,
                style: TextStyle(color: theme.onSurface),
              ),
              trailing: t['name'] == '深色'
                  ? Icon(Icons.check, color: theme.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已切换到${t['name']}主题')),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }

  void _showPageTurnModeDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    PageTurnMode selectedMode = PageTurnMode.slide;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            '翻页模式',
            style: TextStyle(color: theme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: PageTurnMode.values.map((mode) {
              return RadioListTile<PageTurnMode>(
                title: Text(
                  mode.displayName,
                  style: TextStyle(color: theme.onSurface),
                ),
                value: mode,
                groupValue: selectedMode,
                activeColor: theme.primary,
                onChanged: (value) {
                  setState(() {
                    selectedMode = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: theme.subText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('翻页模式已设置为${selectedMode.displayName}')),
                );
              },
              child: Text(
                '确定',
                style: TextStyle(color: theme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTTSSettingsDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    double speechRate = 1.0;
    double pitch = 1.0;
    double volume = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            '朗读设置',
            style: TextStyle(color: theme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.record_voice_over, color: theme.primary),
                  title: Text(
                    'TTS 引擎',
                    style: TextStyle(color: theme.onSurface),
                  ),
                  trailing: DropdownButton<String>(
                    value: '系统默认',
                    dropdownColor: theme.surface,
                    style: TextStyle(color: theme.onSurface),
                    underline: const SizedBox(),
                    items: ['系统默认', 'Google TTS', '百度语音', '讯飞语音']
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, style: TextStyle(color: theme.onSurface)),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.speed, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '语速',
                        style: TextStyle(color: theme.onSurface),
                      ),
                    ),
                    Text(
                      '${speechRate.toStringAsFixed(1)}x',
                      style: TextStyle(color: theme.primary),
                    ),
                  ],
                ),
                Slider(
                  value: speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: theme.primary,
                  thumbColor: theme.primary,
                  onChanged: (value) {
                    setState(() {
                      speechRate = value;
                    });
                  },
                ),
                Row(
                  children: [
                    Icon(Icons.music_note, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '音调',
                        style: TextStyle(color: theme.onSurface),
                      ),
                    ),
                    Text(
                      '${pitch.toStringAsFixed(1)}x',
                      style: TextStyle(color: theme.primary),
                    ),
                  ],
                ),
                Slider(
                  value: pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: theme.primary,
                  thumbColor: theme.primary,
                  onChanged: (value) {
                    setState(() {
                      pitch = value;
                    });
                  },
                ),
                Row(
                  children: [
                    Icon(Icons.volume_up, color: theme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '音量',
                        style: TextStyle(color: theme.onSurface),
                      ),
                    ),
                    Text(
                      '${(volume * 100).toInt()}%',
                      style: TextStyle(color: theme.primary),
                    ),
                  ],
                ),
                Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: theme.primary,
                  thumbColor: theme.primary,
                  onChanged: (value) {
                    setState(() {
                      volume = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(color: theme.subText),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('朗读设置已保存')),
                );
              },
              child: Text(
                '确定',
                style: TextStyle(color: theme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final mockBookmarks = [
      {'book': '斗破苍穹', 'chapter': '第一章 陨落的天才', 'time': '2024-01-15 10:30'},
      {'book': '凡人修仙传', 'chapter': '第三章 七玄门', 'time': '2024-01-14 22:15'},
      {'book': '诡秘之主', 'chapter': '第五章 值夜者', 'time': '2024-01-13 18:45'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Row(
          children: [
            Text(
              '书签管理',
              style: TextStyle(color: theme.onSurface),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已清空所有书签')),
                );
              },
              icon: Icon(Icons.delete_outline, color: theme.error, size: 18),
              label: Text(
                '清空',
                style: TextStyle(color: theme.error, fontSize: 12),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: mockBookmarks.length,
            separatorBuilder: (context, index) => Divider(color: theme.divider),
            itemBuilder: (context, index) {
              final bookmark = mockBookmarks[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  bookmark['book']!,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark['chapter']!,
                      style: TextStyle(color: theme.subText),
                    ),
                    Text(
                      bookmark['time']!,
                      style: TextStyle(
                        color: theme.subText.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已删除书签')),
                    );
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('跳转到 ${bookmark['book']}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }

  void _showReadingHistoryDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final mockHistory = [
      {'date': '今天', 'books': 3, 'chapters': 15, 'minutes': 120},
      {'date': '昨天', 'books': 2, 'chapters': 8, 'minutes': 90},
      {'date': '本周', 'books': 5, 'chapters': 45, 'minutes': 480},
      {'date': '本月', 'books': 12, 'chapters': 156, 'minutes': 2160},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '阅读记录',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总书籍', '12', theme),
                  _buildStatItem('总章节', '156', theme),
                  _buildStatItem('总时长', '36h', theme),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...mockHistory.map((h) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    h['date'] as String,
                    style: TextStyle(color: theme.onSurface),
                  ),
                  subtitle: Text(
                    '${h['books']} 本书 · ${h['chapters']} 章',
                    style: TextStyle(color: theme.subText),
                  ),
                  trailing: Text(
                    '${h['minutes']} 分钟',
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, AppThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.subText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showCacheManagementDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '缓存管理',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.book, color: theme.primary),
              title: Text(
                '书籍缓存',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '缓存的章节内容',
                style: TextStyle(color: theme.subText),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('书籍缓存已清理')),
                  );
                },
                child: Text(
                  '清理',
                  style: TextStyle(color: theme.error),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.image, color: theme.primary),
              title: Text(
                '图片缓存',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '书籍封面和章节图片',
                style: TextStyle(color: theme.subText),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('图片缓存已清理')),
                  );
                },
                child: Text(
                  '清理',
                  style: TextStyle(color: theme.error),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.storage, color: theme.primary),
              title: Text(
                '全部缓存',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '清理所有缓存数据',
                style: TextStyle(color: theme.subText),
              ),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有缓存已清理')),
                  );
                },
                child: Text(
                  '清理全部',
                  style: TextStyle(color: theme.error),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref, AppThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '备份与恢复',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload, color: theme.primary),
              title: Text(
                '导出备份',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '导出书源、书架、设置等数据',
                style: TextStyle(color: theme.subText),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('备份文件已导出')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: theme.primary),
              title: Text(
                '导入备份',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '从备份文件恢复数据',
                style: TextStyle(color: theme.subText),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请选择备份文件')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.share, color: theme.primary),
              title: Text(
                '分享备份',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '通过其他应用分享备份文件',
                style: TextStyle(color: theme.subText),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分享功能开发中')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: theme.subText),
            ),
          ),
        ],
      ),
    );
  }
}
