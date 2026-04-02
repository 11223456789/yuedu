import 'package:flutter/material.dart';

/// 阅读主题配置
class ReaderTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color primaryColor;

  const ReaderTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.primaryColor,
  });

  /// 白天主题
  static const ReaderTheme light = ReaderTheme(
    name: '白天',
    backgroundColor: Color(0xFFF5F5F5),
    textColor: Color(0xFF333333),
    primaryColor: Color(0xFF8B4513),
  );

  /// 夜间主题
  static const ReaderTheme dark = ReaderTheme(
    name: '夜间',
    backgroundColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFB0B0B0),
    primaryColor: Color(0xFFD4AF37),
  );

  /// 护眼主题
  static const ReaderTheme eyeProtection = ReaderTheme(
    name: '护眼',
    backgroundColor: Color(0xFFC7EDCC),
    textColor: Color(0xFF2F4F4F),
    primaryColor: Color(0xFF228B22),
  );

  /// 羊皮纸主题
  static const ReaderTheme parchment = ReaderTheme(
    name: '羊皮纸',
    backgroundColor: Color(0xFFF4ECD8),
    textColor: Color(0xFF5D4E37),
    primaryColor: Color(0xFF8B4513),
  );

  /// 深蓝主题
  static const ReaderTheme darkBlue = ReaderTheme(
    name: '深蓝',
    backgroundColor: Color(0xFF1E3A5F),
    textColor: Color(0xFFE0E0E0),
    primaryColor: Color(0xFF87CEEB),
  );

  /// 粉色主题
  static const ReaderTheme pink = ReaderTheme(
    name: '粉色',
    backgroundColor: Color(0xFFFCE4EC),
    textColor: Color(0xFF880E4F),
    primaryColor: Color(0xFFE91E63),
  );

  /// 咖啡主题
  static const ReaderTheme coffee = ReaderTheme(
    name: '咖啡',
    backgroundColor: Color(0xFF3E2723),
    textColor: Color(0xFFD7CCC8),
    primaryColor: Color(0xFF8D6E63),
  );

  /// 森林主题
  static const ReaderTheme forest = ReaderTheme(
    name: '森林',
    backgroundColor: Color(0xFF1B5E20),
    textColor: Color(0xFFC8E6C9),
    primaryColor: Color(0xFF4CAF50),
  );

  /// 薰衣草主题
  static const ReaderTheme lavender = ReaderTheme(
    name: '薰衣草',
    backgroundColor: Color(0xFFF3E5F5),
    textColor: Color(0xFF4A148C),
    primaryColor: Color(0xFF9C27B0),
  );

  /// 薄荷主题
  static const ReaderTheme mint = ReaderTheme(
    name: '薄荷',
    backgroundColor: Color(0xFFE0F2F1),
    textColor: Color(0xFF004D40),
    primaryColor: Color(0xFF009688),
  );

  /// 黄昏主题
  static const ReaderTheme dusk = ReaderTheme(
    name: '黄昏',
    backgroundColor: Color(0xFF263238),
    textColor: Color(0xFFCFD8DC),
    primaryColor: Color(0xFF607D8B),
  );

  /// 所有主题列表
  static const List<ReaderTheme> allThemes = [
    light,
    dark,
    eyeProtection,
    parchment,
    darkBlue,
    pink,
    coffee,
    forest,
    lavender,
    mint,
    dusk,
  ];

  /// 根据索引获取主题
  static ReaderTheme getThemeByIndex(int index) {
    if (index >= 0 && index < allThemes.length) {
      return allThemes[index];
    }
    return light;
  }
}
