/// 书籍类型
enum BookType {
  text(0),    // 文本小说
  audio(1),   // 有声书
  image(2),   // 漫画/图片
  file(3);    // 本地文件

  final int value;
  const BookType(this.value);

  static BookType fromValue(int v) =>
      BookType.values.firstWhere((e) => e.value == v, orElse: () => BookType.text);
}

/// 翻页模式
enum PageTurnMode {
  cover(0),       // 覆盖
  simulation(1),  // 仿真
  slide(2),       // 滑动
  scroll(3),      // 滚动
  none(4);        // 无动画

  final int value;
  const PageTurnMode(this.value);

  static PageTurnMode fromValue(int v) =>
      PageTurnMode.values.firstWhere((e) => e.value == v, orElse: () => PageTurnMode.slide);

  String get displayName {
    switch (this) {
      case PageTurnMode.cover:      return '覆盖';
      case PageTurnMode.simulation: return '仿真';
      case PageTurnMode.slide:      return '滑动';
      case PageTurnMode.scroll:     return '滚动';
      case PageTurnMode.none:       return '无动画';
    }
  }
}

/// 主题类型
enum ThemeType {
  liujin,   // 鎏金（默认）
  light,    // 亮色
  dark,     // 暗色
  eink,     // E-Ink
  system;   // 跟随系统

  String get displayName {
    switch (this) {
      case ThemeType.liujin: return '鎏金';
      case ThemeType.light:  return '亮色';
      case ThemeType.dark:   return '暗色';
      case ThemeType.eink:   return '墨水屏';
      case ThemeType.system: return '跟随系统';
    }
  }
}

/// 书架排序方式
enum BookSortType {
  recentRead(0),    // 最近阅读
  updateTime(1),    // 更新时间
  bookName(2),      // 书名
  manual(3);        // 手动排序

  final int value;
  const BookSortType(this.value);

  static BookSortType fromValue(int v) =>
      BookSortType.values.firstWhere((e) => e.value == v, orElse: () => BookSortType.recentRead);

  String get displayName {
    switch (this) {
      case BookSortType.recentRead:  return '最近阅读';
      case BookSortType.updateTime:  return '更新时间';
      case BookSortType.bookName:    return '书名';
      case BookSortType.manual:      return '手动排序';
    }
  }
}

/// 朗读类型
enum ReadAloudType {
  tts,   // 系统 TTS
  http;  // HTTP TTS

  String get displayName {
    switch (this) {
      case ReadAloudType.tts:  return '系统朗读';
      case ReadAloudType.http: return '在线朗读';
    }
  }
}

/// 书源类型
enum BookSourceType {
  bookSource(0),  // 书籍书源
  rssSource(1);   // RSS 订阅源

  final int value;
  const BookSourceType(this.value);
}

/// 简繁转换模式
enum ChineseConvertMode {
  off(0),           // 关闭
  simplifiedToTraditional(1),  // 简转繁
  traditionalToSimplified(2);  // 繁转简

  final int value;
  const ChineseConvertMode(this.value);

  static ChineseConvertMode fromValue(int v) =>
      ChineseConvertMode.values.firstWhere((e) => e.value == v, orElse: () => ChineseConvertMode.off);

  String get displayName {
    switch (this) {
      case ChineseConvertMode.off:                      return '关闭';
      case ChineseConvertMode.simplifiedToTraditional:  return '简转繁';
      case ChineseConvertMode.traditionalToSimplified:  return '繁转简';
    }
  }
}

/// 屏幕方向
enum ScreenOrientation {
  followSystem(0),
  portrait(1),
  landscape(2);

  final int value;
  const ScreenOrientation(this.value);

  static ScreenOrientation fromValue(int v) =>
      ScreenOrientation.values.firstWhere((e) => e.value == v, orElse: () => ScreenOrientation.followSystem);
}

/// 书架视图模式
enum BookshelfViewMode {
  list,
  grid3,
  grid4,
  grid5,
  grid6;

  int get columns {
    switch (this) {
      case BookshelfViewMode.list:  return 1;
      case BookshelfViewMode.grid3: return 3;
      case BookshelfViewMode.grid4: return 4;
      case BookshelfViewMode.grid5: return 5;
      case BookshelfViewMode.grid6: return 6;
    }
  }
}

/// 音频播放模式
enum AudioPlayMode {
  listLoop,    // 列表循环
  singleLoop,  // 单曲循环
  random,      // 随机
  listEnd;     // 列表结束停止
}
