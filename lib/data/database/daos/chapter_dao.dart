import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/chapters_table.dart';

part 'chapter_dao.g.dart';

@DriftAccessor(tables: [Chapters])
class ChapterDao extends DatabaseAccessor<AppDatabase> with _$ChapterDaoMixin {
  ChapterDao(super.db);

  Future<List<Chapter>> getChapters(String bookUrl) {
    return (select(chapters)
          ..where((c) => c.bookUrl.equals(bookUrl))
          ..orderBy([(c) => OrderingTerm.asc(c.chapterIndex)]))
        .get();
  }

  Future<Chapter?> getChapter(String bookUrl, int index) {
    return (select(chapters)
          ..where((c) =>
              c.bookUrl.equals(bookUrl) & c.chapterIndex.equals(index)))
        .getSingleOrNull();
  }

  Future<int> getChapterCount(String bookUrl) async {
    final count = countAll();
    final query = selectOnly(chapters)
      ..addColumns([count])
      ..where(chapters.bookUrl.equals(bookUrl));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> insertOrUpdateChapters(List<ChaptersCompanion> chapterList) =>
      batch((b) => b.insertAllOnConflictUpdate(chapters, chapterList));

  Future<int> deleteChapters(String bookUrl) {
    return (delete(chapters)..where((c) => c.bookUrl.equals(bookUrl))).go();
  }
}
