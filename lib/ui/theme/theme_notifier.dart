import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import 'app_theme.dart';

final themeNotifierProvider =
    NotifierProvider<ThemeNotifier, AppThemeData>(ThemeNotifier.new);

/// 兼容旧代码的别名
final appThemeProvider = themeNotifierProvider;

class ThemeNotifier extends Notifier<AppThemeData> {
  @override
  AppThemeData build() {
    _loadTheme();
    return AppTheme.liujin; // 默认鎏金
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final typeName = prefs.getString(PrefKeys.themeType);
    if (typeName != null) {
      final type = ThemeType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => ThemeType.liujin,
      );
      state = AppTheme.fromType(type);
    }
  }

  Future<void> setTheme(ThemeType type) async {
    state = AppTheme.fromType(type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeType, type.name);
  }

  Future<void> followSystem(bool follow) async {
    if (follow) {
      await setTheme(ThemeType.system);
    } else {
      await setTheme(ThemeType.liujin);
    }
  }

  ThemeType get currentType => state.themeType;
}
