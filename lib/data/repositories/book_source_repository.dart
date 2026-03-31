import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/daos/book_source_dao.dart';

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

  Future<void> saveSource(BookSource source) async {
    await _db.bookSourceDao.insertOrUpdateSource(source);
  }

  /// 从 JSON 字符串批量导入书源（兼容 legado 格式）
  Future<int> importFromJson(String jsonStr) async {
    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List;
      final maps = list.map((e) => e as Map<String, dynamic>).toList();
      await _db.bookSourceDao.insertOrUpdateSourcesFromJson(maps);
      return maps.length;
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

  Future<void> toggleExploreEnabled(String url, bool enabled) =>
      _db.bookSourceDao.toggleExploreEnabled(url, enabled);

  /// 导出指定书源列表为 JSON 字符串
  Future<String> exportSourcesToJson(List<BookSource> sources) async {
    return jsonEncode(sources.map(_sourceToMap).toList());
  }
}
