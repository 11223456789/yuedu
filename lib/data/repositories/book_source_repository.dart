import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/book_sources_table.dart';

final bookSourceRepositoryProvider = Provider<BookSourceRepository>((ref) {
  return BookSourceRepository(ref.watch(appDatabaseProvider));
});

class BookSourceRepository {
  final AppDatabase _db;
  BookSourceRepository(this._db);

  Future<List<BookSource>> getAllSources() => _db.bookSourceDao.getAllSources();
  Stream<List<BookSource>> watchAllSources() => _db.bookSourceDao.watchAllSources();
  Future<List<BookSource>> getEnabledSources() => _db.bookSourceDao.getEnabledSources();
  Future<List<BookSource>> searchSources(String keyword) => _db.bookSourceDao.searchSources(keyword);
  Future<BookSource?> getSource(String url) => _db.bookSourceDao.getSource(url);

  Future<void> saveSource(BookSource source) =>
      _db.bookSourceDao.insertOrUpdateSource(
        BookSourcesCompanion(
          bookSourceUrl: Value(source.bookSourceUrl),
          bookSourceName: Value(source.bookSourceName),
          bookSourceGroup: Value(source.bookSourceGroup),
          bookSourceType: Value(source.bookSourceType),
          bookUrlPattern: Value(source.bookUrlPattern),
          customOrder: Value(source.customOrder),
          enabled: Value(source.enabled),
          enabledExplore: Value(source.enabledExplore),
          jsLib: Value(source.jsLib),
          concurrentRate: Value(source.concurrentRate),
          header: Value(source.header),
          loginUrl: Value(source.loginUrl),
          loginUi: Value(source.loginUi),
          loginCheckJs: Value(source.loginCheckJs),
          bookSourceComment: Value(source.bookSourceComment),
          exploreUrl: Value(source.exploreUrl),
          searchUrl: Value(source.searchUrl),
          ruleExplore: Value(source.ruleExplore),
          ruleSearch: Value(source.ruleSearch),
          ruleBookInfo: Value(source.ruleBookInfo),
          ruleToc: Value(source.ruleToc),
          ruleContent: Value(source.ruleContent),
        ),
      );

  /// 从 JSON 字符串批量导入书源（兼容 legado 格式）
  Future<int> importFromJson(String jsonStr) async {
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List;
      final companions = list.map((e) {
        final m = e as Map<String, dynamic>;
        return BookSourcesCompanion(
          bookSourceUrl: Value(m['bookSourceUrl'] as String? ?? ''),
          bookSourceName: Value(m['bookSourceName'] as String? ?? ''),
          bookSourceGroup: Value(m['bookSourceGroup'] as String?),
          bookSourceType: Value(m['bookSourceType'] as int? ?? 0),
          bookUrlPattern: Value(m['bookUrlPattern'] as String?),
          customOrder: Value(m['customOrder'] as int? ?? 0),
          enabled: Value(m['enabled'] as bool? ?? true),
          enabledExplore: Value(m['enabledExplore'] as bool? ?? true),
          jsLib: Value(m['jsLib'] as String?),
          concurrentRate: Value(m['concurrentRate'] as String?),
          header: Value(m['header'] as String?),
          loginUrl: Value(m['loginUrl'] as String?),
          loginUi: Value(m['loginUi'] as String?),
          loginCheckJs: Value(m['loginCheckJs'] as String?),
          bookSourceComment: Value(m['bookSourceComment'] as String?),
          exploreUrl: Value(m['exploreUrl'] as String?),
          searchUrl: Value(m['searchUrl'] as String?),
          ruleExplore: Value(m['ruleExplore'] is Map
              ? jsonEncode(m['ruleExplore'])
              : m['ruleExplore'] as String?),
          ruleSearch: Value(m['ruleSearch'] is Map
              ? jsonEncode(m['ruleSearch'])
              : m['ruleSearch'] as String?),
          ruleBookInfo: Value(m['ruleBookInfo'] is Map
              ? jsonEncode(m['ruleBookInfo'])
              : m['ruleBookInfo'] as String?),
          ruleToc: Value(m['ruleToc'] is Map
              ? jsonEncode(m['ruleToc'])
              : m['ruleToc'] as String?),
          ruleContent: Value(m['ruleContent'] is Map
              ? jsonEncode(m['ruleContent'])
              : m['ruleContent'] as String?),
        );
      }).toList();
      await _db.bookSourceDao.insertOrUpdateSources(companions);
      return companions.length;
    } catch (e) {
      throw Exception('书源导入失败: $e');
    }
  }

  /// 导出书源为 JSON 字符串
  Future<String> exportToJson(List<String> urls) async {
    final sources = urls.isEmpty
        ? await getAllSources()
        : (await Future.wait(urls.map(getSource)))
            .whereType<BookSource>()
            .toList();
    return jsonEncode(sources.map(_sourceToMap).toList());
  }

  Map<String, dynamic> _sourceToMap(BookSource s) => {
        'bookSourceUrl': s.bookSourceUrl,
        'bookSourceName': s.bookSourceName,
        'bookSourceGroup': s.bookSourceGroup,
        'bookSourceType': s.bookSourceType,
        'bookUrlPattern': s.bookUrlPattern,
        'customOrder': s.customOrder,
        'enabled': s.enabled,
        'enabledExplore': s.enabledExplore,
        'jsLib': s.jsLib,
        'concurrentRate': s.concurrentRate,
        'header': s.header,
        'loginUrl': s.loginUrl,
        'loginUi': s.loginUi,
        'loginCheckJs': s.loginCheckJs,
        'bookSourceComment': s.bookSourceComment,
        'exploreUrl': s.exploreUrl,
        'searchUrl': s.searchUrl,
        'ruleExplore': s.ruleExplore,
        'ruleSearch': s.ruleSearch,
        'ruleBookInfo': s.ruleBookInfo,
        'ruleToc': s.ruleToc,
        'ruleContent': s.ruleContent,
      };

  Future<void> deleteSource(String url) => _db.bookSourceDao.deleteSource(url);
  Future<void> toggleEnabled(String url, bool enabled) =>
      _db.bookSourceDao.toggleEnabled(url, enabled);
}
