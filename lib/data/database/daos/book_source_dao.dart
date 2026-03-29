import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/book_sources_table.dart';

part 'book_source_dao.g.dart';

@DriftAccessor(tables: [BookSources])
class BookSourceDao extends DatabaseAccessor<AppDatabase>
    with _$BookSourceDaoMixin {
  BookSourceDao(super.db);

  Future<List<BookSource>> getAllSources() => select(bookSources).get();

  Stream<List<BookSource>> watchAllSources() => select(bookSources).watch();

  Future<List<BookSource>> getEnabledSources() {
    return (select(bookSources)..where((s) => s.enabled.equals(true))).get();
  }

  Future<List<BookSource>> searchSources(String keyword) {
    return (select(bookSources)
          ..where((s) =>
              s.bookSourceName.contains(keyword) |
              s.bookSourceUrl.contains(keyword)))
        .get();
  }

  Future<BookSource?> getSource(String url) {
    return (select(bookSources)
          ..where((s) => s.bookSourceUrl.equals(url)))
        .getSingleOrNull();
  }

  Future<void> insertOrUpdateSource(BookSourcesCompanion source) =>
      into(bookSources).insertOnConflictUpdate(source);

  Future<void> insertOrUpdateSources(List<BookSourcesCompanion> sources) =>
      batch((b) => b.insertAllOnConflictUpdate(bookSources, sources));

  Future<int> deleteSource(String url) {
    return (delete(bookSources)
          ..where((s) => s.bookSourceUrl.equals(url)))
        .go();
  }

  Future<void> toggleEnabled(String url, bool enabled) {
    return (update(bookSources)
          ..where((s) => s.bookSourceUrl.equals(url)))
        .write(BookSourcesCompanion(enabled: Value(enabled)));
  }

  Future<List<BookSource>> getSourcesByGroup(String group) {
    return (select(bookSources)
          ..where((s) => s.bookSourceGroup.equals(group)))
        .get();
  }
}
