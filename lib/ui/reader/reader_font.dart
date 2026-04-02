import 'package:flutter/material.dart';

/// 阅读字体配置
class ReaderFont {
  final String name;
  final String fontFamily;
  final String? fontAsset;

  const ReaderFont({
    required this.name,
    required this.fontFamily,
    this.fontAsset,
  });

  /// 系统默认字体
  static const ReaderFont system = ReaderFont(
    name: '系统默认',
    fontFamily: '',
  );

  /// 思源宋体
  static const ReaderFont notoSerif = ReaderFont(
    name: '思源宋体',
    fontFamily: 'NotoSerifSC',
  );

  /// 思源黑体
  static const ReaderFont notoSans = ReaderFont(
    name: '思源黑体',
    fontFamily: 'NotoSansSC',
  );

  /// 霞鹜文楷
  static const ReaderFont lxgwWenKai = ReaderFont(
    name: '霞鹜文楷',
    fontFamily: 'LXGWWenKai',
  );

  /// 站酷文艺体
  static const ReaderFont zcool = ReaderFont(
    name: '站酷文艺',
    fontFamily: 'ZCOOLXiaoWei',
  );

  /// 阿里巴巴普惠体
  static const ReaderFont alibaba = ReaderFont(
    name: '阿里巴巴',
    fontFamily: 'AlibabaPuHuiTi',
  );

  /// 仿宋
  static const ReaderFont fangSong = ReaderFont(
    name: '仿宋',
    fontFamily: 'FangSong',
  );

  /// 新魏
  static const ReaderFont xinWei = ReaderFont(
    name: '新魏',
    fontFamily: 'XinWei',
  );

  /// 楷体
  static const ReaderFont kaiTi = ReaderFont(
    name: '楷体',
    fontFamily: 'KaiTi',
  );

  /// 宋体
  static const ReaderFont songTi = ReaderFont(
    name: '宋体',
    fontFamily: 'SimSun',
  );

  /// 黑体
  static const ReaderFont heiTi = ReaderFont(
    name: '黑体',
    fontFamily: 'SimHei',
  );

  /// 微软雅黑
  static const ReaderFont yaHei = ReaderFont(
    name: '微软雅黑',
    fontFamily: 'MicrosoftYaHei',
  );

  /// 华文细黑
  static const ReaderFont huaWenXiHei = ReaderFont(
    name: '华文细黑',
    fontFamily: 'STXihei',
  );

  /// 华文楷体
  static const ReaderFont huaWenKaiTi = ReaderFont(
    name: '华文楷体',
    fontFamily: 'STKaiti',
  );

  /// 华文宋体
  static const ReaderFont huaWenSongTi = ReaderFont(
    name: '华文宋体',
    fontFamily: 'STSong',
  );

  /// 所有字体列表
  static const List<ReaderFont> allFonts = [
    system,
    notoSerif,
    notoSans,
    lxgwWenKai,
    zcool,
    alibaba,
    fangSong,
    xinWei,
    kaiTi,
    songTi,
    heiTi,
    yaHei,
    huaWenXiHei,
    huaWenKaiTi,
    huaWenSongTi,
  ];

  /// 根据索引获取字体
  static ReaderFont getFontByIndex(int index) {
    if (index >= 0 && index < allFonts.length) {
      return allFonts[index];
    }
    return system;
  }

  /// 根据字体名获取字体
  static ReaderFont getFontByName(String fontFamily) {
    for (final font in allFonts) {
      if (font.fontFamily == fontFamily) {
        return font;
      }
    }
    return system;
  }
}

/// 字体管理器
class FontManager {
  static final FontManager _instance = FontManager._internal();
  factory FontManager() => _instance;
  FontManager._internal();

  int _currentFontIndex = 0;

  int get currentFontIndex => _currentFontIndex;
  ReaderFont get currentFont => ReaderFont.getFontByIndex(_currentFontIndex);

  void setFont(int index) {
    _currentFontIndex = index;
  }

  /// 获取字体样式
  TextStyle getTextStyle({
    double fontSize = 18,
    double lineHeight = 1.6,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final font = currentFont;
    return TextStyle(
      fontFamily: font.fontFamily.isEmpty ? null : font.fontFamily,
      fontSize: fontSize,
      height: lineHeight,
      color: color,
      fontWeight: fontWeight,
    );
  }
}
