/// 应用信息常量
class AppInfo {
  AppInfo._();

  static const String appName        = '佩宇书屋';
  static const String developer      = 'pirate';
  static const String version        = '1.1.0';
  static const String packageId      = 'com.peiyu.bookhouse';
  static const String urlScheme      = 'peiyubook';
  static const String webServicePort = '1122';

  static const String aboutDesc =
      '佩宇书屋是一款功能强大的跨平台阅读应用，支持自定义书源、多种阅读模式、'
      '离线缓存、朗读、RSS 订阅等丰富功能。界面采用独特的鎏金风格设计，'
      '为您带来优雅的阅读体验。';
}

/// 路由名称常量
class AppRoutes {
  AppRoutes._();

  static const String bookshelf       = '/';
  static const String reader          = '/reader';
  static const String mangaReader     = '/manga_reader';
  static const String bookDetail      = '/book_detail';
  static const String search          = '/search';
  static const String explore         = '/explore';
  static const String bookSource      = '/book_source';
  static const String bookSourceEdit  = '/book_source/edit';
  static const String bookSourceDebug = '/book_source/debug';
  static const String rss             = '/rss';
  static const String rssArticle      = '/rss/article';
  static const String settings        = '/settings';
  static const String about           = '/settings/about';
  static const String readRecord      = '/settings/read_record';
  static const String replaceRule     = '/settings/replace_rule';
  static const String bookmark        = '/bookmark';
  static const String cache           = '/cache';
  static const String qrScanner      = '/qr_scanner';
  static const String changeSource    = '/change_source';
}

/// SharedPreferences Key 常量
class PrefKeys {
  PrefKeys._();

  static const String themeType         = 'theme_type';
  static const String bookshelfViewMode = 'bookshelf_view_mode';
  static const String bookSortType      = 'book_sort_type';
  static const String readFontSize      = 'read_font_size';
  static const String readLineHeight    = 'read_line_height';
  static const String readParaSpacing   = 'read_para_spacing';
  static const String readFontFamily    = 'read_font_family';
  static const String readBgColor       = 'read_bg_color';
  static const String readTextColor     = 'read_text_color';
  static const String readBold          = 'read_bold';
  static const String pageTurnMode      = 'page_turn_mode';
  static const String chineseConvert    = 'chinese_convert';
  static const String screenOrientation = 'screen_orientation';
  static const String hideStatusBar     = 'hide_status_bar';
  static const String showPageHeader    = 'show_page_header';
  static const String showPageFooter    = 'show_page_footer';
  static const String showDivider       = 'show_divider';
  static const String volumeKeyPage     = 'volume_key_page';
  static const String keepScreenOn      = 'keep_screen_on';
  static const String readAloudType     = 'read_aloud_type';
  static const String readAloudSpeed    = 'read_aloud_speed';
  static const String webDavUrl         = 'webdav_url';
  static const String webDavUser        = 'webdav_user';
  static const String webDavPassword    = 'webdav_password';
  static const String cachePath         = 'cache_path';
  static const String autoRefresh       = 'auto_refresh';
  static const String autoDownload      = 'auto_download';
  static const String concurrentCount   = 'concurrent_count';
}
