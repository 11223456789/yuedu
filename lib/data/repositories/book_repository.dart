import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/books_table.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(ref.watch(appDatabaseProvider));
});

class BookRepository {
  final AppDatabase _db;
  BookRepository(this._db);

  Future<List<Book>> getAllBooks() => _db.bookDao.getAllBooks();
  Stream<List<Book>> watchAllBooks() => _db.bookDao.watchAllBooks();
  Future<List<Book>> searchBooks(String keyword) => _db.bookDao.searchBooks(keyword);
  Future<List<Book>> getBooksByGroup(int groupId) => _db.bookDao.getBooksByGroup(groupId);
  Future<Book?> getBook(String bookUrl) => _db.bookDao.getBook(bookUrl);

  Future<void> saveBook(Book book) => _db.bookDao.insertOrUpdateBook(
        BooksCompanion(
          bookUrl: Value(book.bookUrl),
          tocUrl: Value(book.tocUrl),
          origin: Value(book.origin),
          originName: Value(book.originName),
          name: Value(book.name),
          author: Value(book.author),
          kind: Value(book.kind),
          coverUrl: Value(book.coverUrl),
          intro: Value(book.intro),
          type: Value(book.type),
          bookGroup: Value(book.bookGroup),
          latestChapterTitle: Value(book.latestChapterTitle),
          latestChapterTime: Value(book.latestChapterTime),
          totalChapterNum: Value(book.totalChapterNum),
          durChapterTitle: Value(book.durChapterTitle),
          durChapterIndex: Value(book.durChapterIndex),
          durChapterPos: Value(book.durChapterPos),
          durChapterTime: Value(book.durChapterTime),
          canUpdate: Value(book.canUpdate),
          order: Value(book.order),
          variable: Value(book.variable),
          readConfig: Value(book.readConfig),
        ),
      );

  Future<void> updateReadProgress({
    required String bookUrl,
    required int chapterIndex,
    required int chapterPos,
    required String chapterTitle,
  }) =>
      _db.bookDao.updateReadProgress(
        bookUrl: bookUrl,
        chapterIndex: chapterIndex,
        chapterPos: chapterPos,
        chapterTitle: chapterTitle,
      );

  Future<void> deleteBook(String bookUrl) => _db.bookDao.deleteBook(bookUrl);
  Future<void> deleteAllBooks() => _db.bookDao.deleteAllBooks();
}
