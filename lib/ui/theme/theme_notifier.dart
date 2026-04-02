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

/// 主题切换动画控制器
final themeAnimationProvider = StateProvider<double>((ref) => 0.0);

class ThemeNotifier extends Notifier<AppThemeData> {
  AppThemeData? _previousTheme;
  
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

  /// 获取上一个主题（用于动画过渡）
  AppThemeData? get previousTheme => _previousTheme;

  Future<void> setTheme(ThemeType type) async {
    // 保存当前主题作为上一个主题
    _previousTheme = state;
    
    // 应用新主题
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
  
  /// 检查是否是深色主题
  bool get isDarkTheme {
    if (state.themeType == ThemeType.system) {
      // 系统主题模式下，根据系统设置判断
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return state.themeMode == ThemeMode.dark;
  }
  
  /// 获取当前主题的对比色
  Color get contrastColor => isDarkTheme ? Colors.white : Colors.black;
}

/// 主题切换动画组件
class ThemeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  
  const ThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: Theme.of(context),
      duration: duration,
      curve: Curves.easeInOutCubic,
      child: child,
    );
  }
}

/// 带主题动画的页面包装器
class ThemedPage extends ConsumerWidget {
  final Widget child;
  
  const ThemedPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      color: theme.background,
      child: child,
    );
  }
}
