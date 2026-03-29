import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/bookmarks_table.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase>
    with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  Future<List<Bookmark>> getAllBookmarks() {
    return (select(bookmarks)
          ..orderBy([(b) => OrderingTerm.desc(b.time)]))
        .get();
  }

  Future<List<Bookmark>> getBookmarksByBook(String bookUrl) {
    return (select(bookmarks)
          ..where((b) => b.bookUrl.equals(bookUrl))
          ..orderBy([(b) => OrderingTerm.asc(b.chapterIndex)]))
        .get();
  }

  Future<void> insertBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insertOnConflictUpdate(bookmark);

  Future<int> deleteBookmark(int time) {
    return (delete(bookmarks)..where((b) => b.time.equals(time))).go();
  }
}
