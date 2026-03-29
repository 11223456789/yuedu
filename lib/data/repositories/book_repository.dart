import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/web_book/web_book.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository();
});

/// 简化的书籍仓库（内存存储，替代 Drift 数据库）
class BookRepository {
  final Map<String, Book> _books = {};

  Future<List<Book>> getAllBooks() async => _books.values.toList();
  
  Stream<List<Book>> watchAllBooks() async* {
    yield _books.values.toList();
  }
  
  Future<List<Book>> searchBooks(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();
    return _books.values
        .where((b) => 
            b.name.toLowerCase().contains(lowerKeyword) ||
            b.author.toLowerCase().contains(lowerKeyword))
        .toList();
  }
  
  Future<List<Book>> getBooksByGroup(int groupId) async {
    return _books.values.where((b) => b.bookGroup == groupId).toList();
  }
  
  Future<Book?> getBook(String bookUrl) async => _books[bookUrl];

  Future<void> saveBook(Book book) async {
    _books[book.bookUrl] = book;
  }

  Future<void> updateReadProgress({
    required String bookUrl,
    required int chapterIndex,
    required int chapterPos,
    required String chapterTitle,
  }) async {
    final book = _books[bookUrl];
    if (book != null) {
      book.durChapterIndex = chapterIndex;
      book.durChapterPos = chapterPos;
      book.durChapterTitle = chapterTitle;
      book.durChapterTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<void> deleteBook(String bookUrl) async {
    _books.remove(bookUrl);
  }
  
  Future<void> deleteAllBooks() async {
    _books.clear();
  }
}
