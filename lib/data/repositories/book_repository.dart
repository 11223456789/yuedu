import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/book_dao.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository();
});

/// 书籍仓库（使用 BookDao 持久化存储）
class BookRepository {
  final BookDao _dao = BookDao();

  Future<List<Book>> getAllBooks() async => _dao.getAllBooks();
  
  Stream<List<Book>> watchAllBooks() => _dao.watchAllBooks();
  
  Future<List<Book>> searchBooks(String keyword) async => _dao.searchBooks(keyword);
  
  Future<List<Book>> getBooksByGroup(int groupId) async => _dao.getBooksByGroup(groupId);
  
  Future<Book?> getBook(String bookUrl) async => _dao.getBook(bookUrl);

  Future<void> saveBook(Book book) async => _dao.insertOrUpdateBook(book);

  Future<void> addBook(Book book) async => _dao.insertOrUpdateBook(book);

  Future<void> updateReadProgress({
    required String bookUrl,
    required int chapterIndex,
    required int chapterPos,
    required String chapterTitle,
  }) async {
    await _dao.updateReadProgress(
      bookUrl: bookUrl,
      chapterIndex: chapterIndex,
      chapterPos: chapterPos,
      chapterTitle: chapterTitle,
    );
  }

  Future<void> deleteBook(String bookUrl) async => _dao.deleteBook(bookUrl);
  
  Future<void> deleteAllBooks() async => _dao.deleteAllBooks();
}
