import 'package:flutter/material.dart';

/// 佩宇书屋 鎏金主题色彩常量
class AppColors {
  AppColors._();

  // ── 鎏金主题（默认）──────────────────────────────────────
  static const Color liujinBackground = Color(0xFF1A1A1A);   // 深墨背景
  static const Color liujinSurface    = Color(0xFF2A2A2A);   // 卡片/面板背景
  static const Color liujinPrimary    = Color(0xFFC9A84C);   // 鎏金主色
  static const Color liujinSecondary  = Color(0xFFE8D5A3);   // 浅金辅色
  static const Color liujinAccent     = Color(0xFFD4B86A);   // 金色强调
  static const Color liujinDivider    = Color(0xFF3A3218);   // 金色分割线
  static const Color liujinOnBg       = Color(0xFFE8D5A3);   // 背景上的文字
  static const Color liujinOnSurface  = Color(0xFFD4B86A);   // 面板上的文字
  static const Color liujinSubText    = Color(0xFF8A7A50);   // 次要文字
  static const Color liujinError      = Color(0xFFCF6679);   // 错误色

  // ── 亮色主题 ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAF8F3);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightPrimary    = Color(0xFF8B6914);
  static const Color lightSecondary  = Color(0xFFC9A84C);
  static const Color lightOnBg       = Color(0xFF1A1A1A);
  static const Color lightOnSurface  = Color(0xFF333333);
  static const Color lightSubText    = Color(0xFF888888);
  static const Color lightDivider    = Color(0xFFE0D5B0);
  static const Color lightError      = Color(0xFFB00020);

  // ── 暗色主题 ─────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF121212);
  static const Color darkSurface     = Color(0xFF1E1E1E);
  static const Color darkPrimary     = Color(0xFFBB86FC);
  static const Color darkSecondary   = Color(0xFF03DAC6);
  static const Color darkOnBg        = Color(0xFFE0E0E0);
  static const Color darkOnSurface   = Color(0xFFCCCCCC);
  static const Color darkSubText     = Color(0xFF888888);
  static const Color darkDivider     = Color(0xFF2C2C2C);
  static const Color darkError       = Color(0xFFCF6679);

  // ── E-Ink 主题 ────────────────────────────────────────────
  static const Color einkBackground  = Color(0xFFFFFFFF);
  static const Color einkSurface     = Color(0xFFF5F5F5);
  static const Color einkPrimary     = Color(0xFF000000);
  static const Color einkSecondary   = Color(0xFF444444);
  static const Color einkOnBg        = Color(0xFF000000);
  static const Color einkOnSurface   = Color(0xFF222222);
  static const Color einkSubText     = Color(0xFF666666);
  static const Color einkDivider     = Color(0xFFCCCCCC);
  static const Color einkError       = Color(0xFF880000);

  // ── 通用颜色别名（用于简化代码）───────────────────────────────
  static const Color textPrimary   = liujinOnBg;
  static const Color textSecondary = liujinSubText;
  static const Color gold          = liujinPrimary;
  static const Color divider       = liujinDivider;

  // ── 阅读背景预设 ──────────────────────────────────────────
  static const List<Color> readBgPresets = [
    Color(0xFF1A1A1A),  // 鎏金夜读
    Color(0xFFFAF8F3),  // 米白护眼
    Color(0xFFE8F5E9),  // 淡绿清新
    Color(0xFFFFF3E0),  // 暖黄温馨
    Color(0xFFE3F2FD),  // 淡蓝清爽
    Color(0xFF212121),  // 纯黑护眼
  ];

  static const List<Color> readTextPresets = [
    Color(0xFFE8D5A3),  // 鎏金文字
    Color(0xFF333333),  // 深灰文字
    Color(0xFF1A1A1A),  // 纯黑文字
    Color(0xFF4A4A4A),  // 中灰文字
    Color(0xFFE0E0E0),  // 浅灰文字（暗背景）
  ];
}
