import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/bookmarks_table.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(appDatabaseProvider));
});

class BookmarkRepository {
  final AppDatabase _db;
  BookmarkRepository(this._db);

  Future<List<Bookmark>> getAllBookmarks() => _db.bookmarkDao.getAllBookmarks();
  Future<List<Bookmark>> getBookmarksByBook(String bookUrl) =>
      _db.bookmarkDao.getBookmarksByBook(bookUrl);

  Future<void> addBookmark({
    required String bookUrl,
    required String bookName,
    required int chapterIndex,
    required int chapterPos,
    required String chapterName,
    required String content,
  }) =>
      _db.bookmarkDao.insertBookmark(
        BookmarksCompanion(
          time: Value(DateTime.now().millisecondsSinceEpoch),
          bookUrl: Value(bookUrl),
          bookName: Value(bookName),
          chapterIndex: Value(chapterIndex),
          chapterPos: Value(chapterPos),
          chapterName: Value(chapterName),
          content: Value(content),
        ),
      );

  Future<void> deleteBookmark(int time) => _db.bookmarkDao.deleteBookmark(time);
}
