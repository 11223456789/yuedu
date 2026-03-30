import 'dart:convert';

/// 书源 DAO（内存实现）
class BookSourceDao {
  final Map<String, BookSource> _sources = {};

  Future<List<BookSource>> getAllSources() async => _sources.values.toList();

  Stream<List<BookSource>> watchAllSources() async* {
    yield _sources.values.toList();
  }

  Future<List<BookSource>> getEnabledSources() async =>
      _sources.values.where((s) => s.enabled).toList();

  Future<BookSource?> getSource(String url) async => _sources[url];

  Future<void> insertOrUpdateSource(BookSource source) async {
    _sources[source.bookSourceUrl] = source;
  }

  Future<void> insertOrUpdateSourcesFromJson(List<Map<String, dynamic>> sources) async {
    for (final m in sources) {
      _sources[m['bookSourceUrl'] as String] = BookSource(
        bookSourceUrl: m['bookSourceUrl'] as String? ?? '',
        bookSourceName: m['bookSourceName'] as String? ?? '',
        bookSourceGroup: m['bookSourceGroup'] as String?,
        bookSourceType: m['bookSourceType'] as int? ?? 0,
        bookUrlPattern: m['bookUrlPattern'] as String?,
        customOrder: m['customOrder'] as int? ?? 0,
        enabled: m['enabled'] as bool? ?? true,
        enabledExplore: m['enabledExplore'] as bool? ?? true,
        jsLib: m['jsLib'] as String?,
        concurrentRate: m['concurrentRate'] as String?,
        header: m['header'] as String?,
        loginUrl: m['loginUrl'] as String?,
        loginUi: m['loginUi'] as String?,
        loginCheckJs: m['loginCheckJs'] as String?,
        bookSourceComment: m['bookSourceComment'] as String?,
        exploreUrl: m['exploreUrl'] as String?,
        searchUrl: m['searchUrl'] as String?,
        ruleExplore: m['ruleExplore'] is Map
            ? jsonEncode(m['ruleExplore'])
            : m['ruleExplore'] as String?,
        ruleSearch: m['ruleSearch'] is Map
            ? jsonEncode(m['ruleSearch'])
            : m['ruleSearch'] as String?,
        ruleBookInfo: m['ruleBookInfo'] is Map
            ? jsonEncode(m['ruleBookInfo'])
            : m['ruleBookInfo'] as String?,
        ruleToc: m['ruleToc'] is Map
            ? jsonEncode(m['ruleToc'])
            : m['ruleToc'] as String?,
        ruleContent: m['ruleContent'] is Map
            ? jsonEncode(m['ruleContent'])
            : m['ruleContent'] as String?,
        respondTime: m['respondTime'] as int? ?? 100,
      );
    }
  }

  Future<void> deleteSource(String url) async => _sources.remove(url);

  Future<void> toggleEnabled(String url, bool enabled) async {
    final source = _sources[url];
    if (source != null) {
      _sources[url] = BookSource(
        bookSourceUrl: source.bookSourceUrl,
        bookSourceName: source.bookSourceName,
        bookSourceGroup: source.bookSourceGroup,
        bookSourceType: source.bookSourceType,
        bookUrlPattern: source.bookUrlPattern,
        customOrder: source.customOrder,
        enabled: enabled,
        enabledExplore: source.enabledExplore,
        jsLib: source.jsLib,
        concurrentRate: source.concurrentRate,
        header: source.header,
        loginUrl: source.loginUrl,
        loginUi: source.loginUi,
        loginCheckJs: source.loginCheckJs,
        bookSourceComment: source.bookSourceComment,
        exploreUrl: source.exploreUrl,
        searchUrl: source.searchUrl,
        ruleExplore: source.ruleExplore,
        ruleSearch: source.ruleSearch,
        ruleBookInfo: source.ruleBookInfo,
        ruleToc: source.ruleToc,
        ruleContent: source.ruleContent,
        respondTime: source.respondTime,
      );
    }
  }

  Future<List<BookSource>> searchSources(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();
    return _sources.values.where((s) {
      return s.bookSourceName.toLowerCase().contains(lowerKeyword) ||
          s.bookSourceUrl.toLowerCase().contains(lowerKeyword) ||
          (s.bookSourceGroup?.toLowerCase().contains(lowerKeyword) ?? false);
    }).toList();
  }
}

/// 书源数据类
class BookSource {
  final String bookSourceUrl;
  final String bookSourceName;
  final String? bookSourceGroup;
  final int bookSourceType;
  final String? bookUrlPattern;
  final int customOrder;
  final bool enabled;
  final bool enabledExplore;
  final String? jsLib;
  final String? concurrentRate;
  final String? header;
  final String? loginUrl;
  final String? loginUi;
  final String? loginCheckJs;
  final String? bookSourceComment;
  final String? exploreUrl;
  final String? searchUrl;
  final String? ruleExplore;
  final String? ruleSearch;
  final String? ruleBookInfo;
  final String? ruleToc;
  final String? ruleContent;
  final int respondTime;

  BookSource({
    required this.bookSourceUrl,
    required this.bookSourceName,
    this.bookSourceGroup,
    this.bookSourceType = 0,
    this.bookUrlPattern,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.jsLib,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.bookSourceComment,
    this.exploreUrl,
    this.searchUrl,
    this.ruleExplore,
    this.ruleSearch,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
    this.respondTime = 100,
  });
}
