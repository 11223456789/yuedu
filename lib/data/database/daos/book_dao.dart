import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/books_table.dart';

part 'book_dao.g.dart';

@DriftAccessor(tables: [Books])
class BookDao extends DatabaseAccessor<AppDatabase> with _$BookDaoMixin {
  BookDao(super.db);

  /// 获取所有书籍
  Future<List<Book>> getAllBooks() => select(books).get();

  /// 监听所有书籍（响应式）
  Stream<List<Book>> watchAllBooks() => select(books).watch();

  /// 按书名搜索
  Future<List<Book>> searchBooks(String keyword) {
    return (select(books)
          ..where((b) =>
              b.name.contains(keyword) | b.author.contains(keyword)))
        .get();
  }

  /// 按分组获取书籍
  Future<List<Book>> getBooksByGroup(int groupId) {
    return (select(books)..where((b) => b.bookGroup.equals(groupId))).get();
  }

  /// 获取单本书籍
  Future<Book?> getBook(String bookUrl) {
    return (select(books)..where((b) => b.bookUrl.equals(bookUrl)))
        .getSingleOrNull();
  }

  /// 插入或更新书籍
  Future<void> insertOrUpdateBook(BooksCompanion book) =>
      into(books).insertOnConflictUpdate(book);

  /// 更新阅读进度
  Future<void> updateReadProgress({
    required String bookUrl,
    required int chapterIndex,
    required int chapterPos,
    required String chapterTitle,
  }) {
    return (update(books)..where((b) => b.bookUrl.equals(bookUrl))).write(
      BooksCompanion(
        durChapterIndex: Value(chapterIndex),
        durChapterPos: Value(chapterPos),
        durChapterTitle: Value(chapterTitle),
        durChapterTime: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 删除书籍
  Future<int> deleteBook(String bookUrl) {
    return (delete(books)..where((b) => b.bookUrl.equals(bookUrl))).go();
  }

  /// 删除所有书籍
  Future<int> deleteAllBooks() => delete(books).go();

  /// 更新最新章节信息
  Future<void> updateLatestChapter({
    required String bookUrl,
    required String latestChapterTitle,
    required int latestChapterTime,
    required int totalChapterNum,
  }) {
    return (update(books)..where((b) => b.bookUrl.equals(bookUrl))).write(
      BooksCompanion(
        latestChapterTitle: Value(latestChapterTitle),
        latestChapterTime: Value(latestChapterTime),
        totalChapterNum: Value(totalChapterNum),
      ),
    );
  }
}
