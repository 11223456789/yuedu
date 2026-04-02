import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../entities/rule/search_rule.dart';
import '../../entities/rule/book_info_rule.dart';
import '../../entities/rule/toc_rule.dart';
import '../../entities/rule/content_rule.dart';
import '../../entities/rule/explore_rule.dart';

/// 书源 DAO（使用 SharedPreferences 持久化存储）
class BookSourceDao {
  static const String _key = 'book_sources';
  
  final Map<String, BookSource> _cache = {};
  bool _loaded = false;

  /// 加载数据
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data);
        for (final item in list) {
          final source = BookSource.fromJson(item);
          _cache[source.bookSourceUrl] = source;
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  /// 保存数据
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.values.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<BookSource>> getAllSources() async {
    await _ensureLoaded();
    return _cache.values.toList();
  }

  Stream<List<BookSource>> watchAllSources() async* {
    await _ensureLoaded();
    yield _cache.values.toList();
  }

  Future<List<BookSource>> getEnabledSources() async {
    await _ensureLoaded();
    return _cache.values.where((s) => s.enabled).toList();
  }

  Future<BookSource?> getSource(String url) async {
    await _ensureLoaded();
    return _cache[url];
  }

  Future<void> insertOrUpdateSource(BookSource source) async {
    await _ensureLoaded();
    _cache[source.bookSourceUrl] = source;
    await _save();
  }

  Future<void> insertOrUpdateSourcesFromJson(List<Map<String, dynamic>> sources) async {
    await _ensureLoaded();
    for (final m in sources) {
      final source = BookSource.fromJson(m);
      _cache[source.bookSourceUrl] = source;
    }
    await _save();
  }

  Future<void> deleteSource(String url) async {
    await _ensureLoaded();
    _cache.remove(url);
    await _save();
  }

  Future<void> toggleEnabled(String url, bool enabled) async {
    await _ensureLoaded();
    final source = _cache[url];
    if (source != null) {
      _cache[url] = source.copyWith(enabled: enabled);
      await _save();
    }
  }

  Future<void> toggleExploreEnabled(String url, bool enabled) async {
    await _ensureLoaded();
    final source = _cache[url];
    if (source != null) {
      _cache[url] = source.copyWith(enabledExplore: enabled);
      await _save();
    }
  }

  Future<void> updateSourceResponseTime(String url, int responseTime) async {
    await _ensureLoaded();
    final source = _cache[url];
    if (source != null) {
      _cache[url] = source.copyWith(respondTime: responseTime);
      await _save();
    }
  }

  Future<List<BookSource>> searchSources(String keyword) async {
    await _ensureLoaded();
    final lowerKeyword = keyword.toLowerCase();
    return _cache.values.where((s) {
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
  final int lastUpdateTime;

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
    this.lastUpdateTime = 0,
  });

  /// 缓存解析后的规则
  SearchRule? _searchRuleCache;
  BookInfoRule? _bookInfoRuleCache;
  TocRule? _tocRuleCache;
  ContentRule? _contentRuleCache;
  ExploreRule? _exploreRuleCache;

  /// 获取搜索规则
  SearchRule get searchRule {
    if (_searchRuleCache != null) return _searchRuleCache!;
    _searchRuleCache = SearchRule.fromJson(ruleSearch);
    return _searchRuleCache!;
  }

  /// 获取书籍详情规则
  BookInfoRule get bookInfoRule {
    if (_bookInfoRuleCache != null) return _bookInfoRuleCache!;
    _bookInfoRuleCache = BookInfoRule.fromJson(ruleBookInfo);
    return _bookInfoRuleCache!;
  }

  /// 获取目录规则
  TocRule get tocRule {
    if (_tocRuleCache != null) return _tocRuleCache!;
    _tocRuleCache = TocRule.fromJson(ruleToc);
    return _tocRuleCache!;
  }

  /// 获取正文规则
  ContentRule get contentRule {
    if (_contentRuleCache != null) return _contentRuleCache!;
    _contentRuleCache = ContentRule.fromJson(ruleContent);
    return _contentRuleCache!;
  }

  /// 获取发现规则
  ExploreRule get exploreRule {
    if (_exploreRuleCache != null) return _exploreRuleCache!;
    _exploreRuleCache = ExploreRule.fromJson(ruleExplore);
    return _exploreRuleCache!;
  }

  /// 从 JSON 创建
  factory BookSource.fromJson(Map<String, dynamic> m) {
    return BookSource(
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
      ruleExplore: m['ruleExplore'] is Map ? jsonEncode(m['ruleExplore']) : m['ruleExplore'] as String?,
      ruleSearch: m['ruleSearch'] is Map ? jsonEncode(m['ruleSearch']) : m['ruleSearch'] as String?,
      ruleBookInfo: m['ruleBookInfo'] is Map ? jsonEncode(m['ruleBookInfo']) : m['ruleBookInfo'] as String?,
      ruleToc: m['ruleToc'] is Map ? jsonEncode(m['ruleToc']) : m['ruleToc'] as String?,
      ruleContent: m['ruleContent'] is Map ? jsonEncode(m['ruleContent']) : m['ruleContent'] as String?,
      respondTime: m['respondTime'] as int? ?? 100,
      lastUpdateTime: m['lastUpdateTime'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'bookSourceType': bookSourceType,
      'bookUrlPattern': bookUrlPattern,
      'customOrder': customOrder,
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'jsLib': jsLib,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'bookSourceComment': bookSourceComment,
      'exploreUrl': exploreUrl,
      'searchUrl': searchUrl,
      'ruleExplore': ruleExplore,
      'ruleSearch': ruleSearch,
      'ruleBookInfo': ruleBookInfo,
      'ruleToc': ruleToc,
      'ruleContent': ruleContent,
      'respondTime': respondTime,
      'lastUpdateTime': lastUpdateTime,
    };
  }

  /// 创建副本并更新指定字段
  BookSource copyWith({
    String? bookSourceUrl,
    String? bookSourceName,
    String? bookSourceGroup,
    int? bookSourceType,
    String? bookUrlPattern,
    int? customOrder,
    bool? enabled,
    bool? enabledExplore,
    String? jsLib,
    String? concurrentRate,
    String? header,
    String? loginUrl,
    String? loginUi,
    String? loginCheckJs,
    String? bookSourceComment,
    String? exploreUrl,
    String? searchUrl,
    String? ruleExplore,
    String? ruleSearch,
    String? ruleBookInfo,
    String? ruleToc,
    String? ruleContent,
    int? respondTime,
    int? lastUpdateTime,
  }) {
    return BookSource(
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
      bookSourceName: bookSourceName ?? this.bookSourceName,
      bookSourceGroup: bookSourceGroup ?? this.bookSourceGroup,
      bookSourceType: bookSourceType ?? this.bookSourceType,
      bookUrlPattern: bookUrlPattern ?? this.bookUrlPattern,
      customOrder: customOrder ?? this.customOrder,
      enabled: enabled ?? this.enabled,
      enabledExplore: enabledExplore ?? this.enabledExplore,
      jsLib: jsLib ?? this.jsLib,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      header: header ?? this.header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      bookSourceComment: bookSourceComment ?? this.bookSourceComment,
      exploreUrl: exploreUrl ?? this.exploreUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      ruleExplore: ruleExplore ?? this.ruleExplore,
      ruleSearch: ruleSearch ?? this.ruleSearch,
      ruleBookInfo: ruleBookInfo ?? this.ruleBookInfo,
      ruleToc: ruleToc ?? this.ruleToc,
      ruleContent: ruleContent ?? this.ruleContent,
      respondTime: respondTime ?? this.respondTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}
