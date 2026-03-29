import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';

/// 鎏金主题数据
class AppThemeData {
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color divider;
  final Color onBackground;
  final Color onSurface;
  final Color subText;
  final Color error;
  final ThemeType themeType;
  final ThemeMode themeMode;
  final TextTheme textTheme;
  final Color textColor;

  const AppThemeData({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.divider,
    required this.onBackground,
    required this.onSurface,
    required this.subText,
    required this.error,
    required this.themeType,
    this.themeMode = ThemeMode.dark,
    required this.textTheme,
    required this.textColor,
  });
}

class AppTheme {
  AppTheme._();

  /// 构建文本主题
  static TextTheme _buildTextTheme(Color onBackground, Color subText) {
    return TextTheme(
      bodyLarge: TextStyle(color: onBackground, fontSize: 16),
      bodyMedium: TextStyle(color: onBackground, fontSize: 14),
      bodySmall: TextStyle(color: subText, fontSize: 12),
      titleLarge: TextStyle(color: onBackground, fontSize: 20, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: onBackground, fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: onBackground, fontSize: 14),
      labelLarge: TextStyle(color: onBackground, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  /// 鎏金主题（默认）
  static final AppThemeData liujin = AppThemeData(
    background:   AppColors.liujinBackground,
    surface:      AppColors.liujinSurface,
    primary:      AppColors.liujinPrimary,
    secondary:    AppColors.liujinSecondary,
    accent:       AppColors.liujinAccent,
    divider:      AppColors.liujinDivider,
    onBackground: AppColors.liujinOnBg,
    onSurface:    AppColors.liujinOnSurface,
    subText:      AppColors.liujinSubText,
    error:        AppColors.liujinError,
    themeType:    ThemeType.liujin,
    themeMode:    ThemeMode.dark,
    textColor:    AppColors.liujinOnBg,
    textTheme:    _buildTextTheme(AppColors.liujinOnBg, AppColors.liujinSubText),
  );

  /// 亮色主题
  static final AppThemeData light = AppThemeData(
    background:   AppColors.lightBackground,
    surface:      AppColors.lightSurface,
    primary:      AppColors.lightPrimary,
    secondary:    AppColors.lightSecondary,
    accent:       AppColors.lightSecondary,
    divider:      AppColors.lightDivider,
    onBackground: AppColors.lightOnBg,
    onSurface:    AppColors.lightOnSurface,
    subText:      AppColors.lightSubText,
    error:        AppColors.lightError,
    themeType:    ThemeType.light,
    themeMode:    ThemeMode.light,
    textColor:    AppColors.lightOnBg,
    textTheme:    _buildTextTheme(AppColors.lightOnBg, AppColors.lightSubText),
  );

  /// 暗色主题
  static final AppThemeData dark = AppThemeData(
    background:   AppColors.darkBackground,
    surface:      AppColors.darkSurface,
    primary:      AppColors.darkPrimary,
    secondary:    AppColors.darkSecondary,
    accent:       AppColors.darkSecondary,
    divider:      AppColors.darkDivider,
    onBackground: AppColors.darkOnBg,
    onSurface:    AppColors.darkOnSurface,
    subText:      AppColors.darkSubText,
    error:        AppColors.darkError,
    themeType:    ThemeType.dark,
    themeMode:    ThemeMode.dark,
    textColor:    AppColors.darkOnBg,
    textTheme:    _buildTextTheme(AppColors.darkOnBg, AppColors.darkSubText),
  );

  /// E-Ink 主题
  static final AppThemeData eink = AppThemeData(
    background:   AppColors.einkBackground,
    surface:      AppColors.einkSurface,
    primary:      AppColors.einkPrimary,
    secondary:    AppColors.einkSecondary,
    accent:       AppColors.einkSecondary,
    divider:      AppColors.einkDivider,
    onBackground: AppColors.einkOnBg,
    onSurface:    AppColors.einkOnSurface,
    subText:      AppColors.einkSubText,
    error:        AppColors.einkError,
    themeType:    ThemeType.eink,
    themeMode:    ThemeMode.light,
    textColor:    AppColors.einkOnBg,
    textTheme:    _buildTextTheme(AppColors.einkOnBg, AppColors.einkSubText),
  );

  static AppThemeData fromType(ThemeType type) {
    switch (type) {
      case ThemeType.liujin: return liujin;
      case ThemeType.light:  return light;
      case ThemeType.dark:   return dark;
      case ThemeType.eink:   return eink;
      case ThemeType.system: return liujin; // 跟随系统时默认鎏金
    }
  }

  /// 构建 Flutter MaterialTheme
  static ThemeData buildMaterialTheme(AppThemeData t) {
    final colorScheme = ColorScheme(
      brightness: t.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      primary: t.primary,
      onPrimary: t.background,
      secondary: t.secondary,
      onSecondary: t.background,
      error: t.error,
      onError: Colors.white,
      background: t.background,
      onBackground: t.onBackground,
      surface: t.surface,
      onSurface: t.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.background,
      cardColor: t.surface,
      dividerColor: t.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: t.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: t.primary),
        actionsIconTheme: IconThemeData(color: t.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.primary,
        unselectedItemColor: t.subText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: t.primary,
        unselectedLabelColor: t.subText,
        indicatorColor: t.primary,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: t.onBackground, fontSize: 16),
        bodyMedium: TextStyle(color: t.onBackground, fontSize: 14),
        bodySmall: TextStyle(color: t.subText, fontSize: 12),
        titleLarge: TextStyle(color: t.primary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: t.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: t.onSurface, fontSize: 14),
        labelLarge: TextStyle(color: t.primary, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: t.primary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.primary,
          side: BorderSide(color: t.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: t.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: t.subText),
        hintStyle: TextStyle(color: t.subText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? t.primary : t.subText),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? t.primary.withOpacity(0.4)
                : t.divider),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? t.primary : Colors.transparent),
        checkColor: MaterialStateProperty.all(t.background),
        side: BorderSide(color: t.primary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.primary,
        inactiveTrackColor: t.divider,
        thumbColor: t.primary,
        overlayColor: t.primary.withOpacity(0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.primary,
        linearTrackColor: t.divider,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: t.surface,
        titleTextStyle: TextStyle(color: t.primary, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: t.onSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surface,
        contentTextStyle: TextStyle(color: t.onSurface),
        actionTextColor: t.primary,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: t.onSurface,
        iconColor: t.primary,
      ),
    );
  }
}
