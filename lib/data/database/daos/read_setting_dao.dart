import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 阅读设置数据类
class ReadSetting {
  // 字体设置
  double fontSize;
  double lineHeight;
  String fontFamily;
  
  // 主题设置
  int themeIndex; // 0: 白天, 1: 夜间, 2: 护眼, 3: 羊皮纸
  int textColor;
  int backgroundColor;
  
  // 翻页设置
  int pageTurnMode; // 0: 覆盖, 1: 仿真, 2: 滑动, 3: 滚动, 4: 无动画
  
  // 其他设置
  bool keepScreenOn;
  bool hideStatusBar;
  bool volumeKeyTurnPage;
  bool clickTurnPage;
  bool swipeTurnPage;
  bool showBattery;
  bool showTime;
  bool showProgress;
  
  // 朗读设置
  double ttsSpeed;
  double ttsPitch;
  String ttsEngine;

  ReadSetting({
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.fontFamily = 'system',
    this.themeIndex = 0,
    this.textColor = 0xFF000000,
    this.backgroundColor = 0xFFFFFFFF,
    this.pageTurnMode = 0,
    this.keepScreenOn = true,
    this.hideStatusBar = false,
    this.volumeKeyTurnPage = true,
    this.clickTurnPage = true,
    this.swipeTurnPage = true,
    this.showBattery = true,
    this.showTime = true,
    this.showProgress = true,
    this.ttsSpeed = 1.0,
    this.ttsPitch = 1.0,
    this.ttsEngine = 'system',
  });

  factory ReadSetting.fromJson(Map<String, dynamic> json) {
    return ReadSetting(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      fontFamily: json['fontFamily'] as String? ?? 'system',
      themeIndex: json['themeIndex'] as int? ?? 0,
      textColor: json['textColor'] as int? ?? 0xFF000000,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
      pageTurnMode: json['pageTurnMode'] as int? ?? 0,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      hideStatusBar: json['hideStatusBar'] as bool? ?? false,
      volumeKeyTurnPage: json['volumeKeyTurnPage'] as bool? ?? true,
      clickTurnPage: json['clickTurnPage'] as bool? ?? true,
      swipeTurnPage: json['swipeTurnPage'] as bool? ?? true,
      showBattery: json['showBattery'] as bool? ?? true,
      showTime: json['showTime'] as bool? ?? true,
      showProgress: json['showProgress'] as bool? ?? true,
      ttsSpeed: (json['ttsSpeed'] as num?)?.toDouble() ?? 1.0,
      ttsPitch: (json['ttsPitch'] as num?)?.toDouble() ?? 1.0,
      ttsEngine: json['ttsEngine'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontFamily': fontFamily,
      'themeIndex': themeIndex,
      'textColor': textColor,
      'backgroundColor': backgroundColor,
      'pageTurnMode': pageTurnMode,
      'keepScreenOn': keepScreenOn,
      'hideStatusBar': hideStatusBar,
      'volumeKeyTurnPage': volumeKeyTurnPage,
      'clickTurnPage': clickTurnPage,
      'swipeTurnPage': swipeTurnPage,
      'showBattery': showBattery,
      'showTime': showTime,
      'showProgress': showProgress,
      'ttsSpeed': ttsSpeed,
      'ttsPitch': ttsPitch,
      'ttsEngine': ttsEngine,
    };
  }

  ReadSetting copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    int? themeIndex,
    int? textColor,
    int? backgroundColor,
    int? pageTurnMode,
    bool? keepScreenOn,
    bool? hideStatusBar,
    bool? volumeKeyTurnPage,
    bool? clickTurnPage,
    bool? swipeTurnPage,
    bool? showBattery,
    bool? showTime,
    bool? showProgress,
    double? ttsSpeed,
    double? ttsPitch,
    String? ttsEngine,
  }) {
    return ReadSetting(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      themeIndex: themeIndex ?? this.themeIndex,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      hideStatusBar: hideStatusBar ?? this.hideStatusBar,
      volumeKeyTurnPage: volumeKeyTurnPage ?? this.volumeKeyTurnPage,
      clickTurnPage: clickTurnPage ?? this.clickTurnPage,
      swipeTurnPage: swipeTurnPage ?? this.swipeTurnPage,
      showBattery: showBattery ?? this.showBattery,
      showTime: showTime ?? this.showTime,
      showProgress: showProgress ?? this.showProgress,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsEngine: ttsEngine ?? this.ttsEngine,
    );
  }
}

/// 阅读设置 DAO（使用 SharedPreferences 持久化存储）
class ReadSettingDao {
  static const String _key = 'read_setting';
  
  ReadSetting? _cache;

  Future<ReadSetting> getSetting() async {
    if (_cache != null) return _cache!;
    
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _cache = ReadSetting.fromJson(json);
        return _cache!;
      } catch (_) {}
    }
    
    _cache = ReadSetting();
    return _cache!;
  }

  Future<void> saveSetting(ReadSetting setting) async {
    _cache = setting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(setting.toJson()));
  }

  Future<void> updateFontSize(double fontSize) async {
    final setting = await getSetting();
    await saveSetting(setting.copyWith(fontSize: fontSize));
  }

  Future<void> updateLineHeight(double lineHeight) async {
    final setting = await getSetting();
    await saveSetting(setting.copyWith(lineHeight: lineHeight));
  }

  Future<void> updateTheme(int themeIndex, int textColor, int backgroundColor) async {
    final setting = await getSetting();
    await saveSetting(setting.copyWith(
      themeIndex: themeIndex,
      textColor: textColor,
      backgroundColor: backgroundColor,
    ));
  }

  Future<void> updatePageTurnMode(int mode) async {
    final setting = await getSetting();
    await saveSetting(setting.copyWith(pageTurnMode: mode));
  }

  Future<void> updateTtsSettings({
    double? speed,
    double? pitch,
    String? engine,
  }) async {
    final setting = await getSetting();
    await saveSetting(setting.copyWith(
      ttsSpeed: speed,
      ttsPitch: pitch,
      ttsEngine: engine,
    ));
  }
}
