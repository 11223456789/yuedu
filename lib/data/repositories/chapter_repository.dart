import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/chapters_table.dart';

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return ChapterRepository(ref.watch(appDatabaseProvider));
});

class ChapterRepository {
  final AppDatabase _db;
  ChapterRepository(this._db);

  Future<List<Chapter>> getChapters(String bookUrl) =>
      _db.chapterDao.getChapters(bookUrl);

  Future<Chapter?> getChapter(String bookUrl, int index) =>
      _db.chapterDao.getChapter(bookUrl, index);

  Future<int> getChapterCount(String bookUrl) =>
      _db.chapterDao.getChapterCount(bookUrl);

  Future<void> saveChapters(String bookUrl, List<Map<String, dynamic>> chapters) {
    final companions = chapters.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      return ChaptersCompanion(
        url: Value(c['url'] as String? ?? ''),
        bookUrl: Value(bookUrl),
        title: Value(c['title'] as String? ?? ''),
        isVolume: Value(c['isVolume'] as bool? ?? false),
        baseUrl: Value(c['baseUrl'] as String? ?? ''),
        chapterIndex: Value(c['index'] as int? ?? i),
        isVip: Value(c['isVip'] as bool? ?? false),
        isPay: Value(c['isPay'] as bool? ?? false),
        resourceUrl: Value(c['resourceUrl'] as String?),
        tag: Value(c['tag'] as String?),
        start: Value(c['start'] as int?),
        end: Value(c['end'] as int?),
        variable: Value(c['variable'] as String?),
      );
    }).toList();
    return _db.chapterDao.insertOrUpdateChapters(companions);
  }

  Future<void> deleteChapters(String bookUrl) =>
      _db.chapterDao.deleteChapters(bookUrl);
}
