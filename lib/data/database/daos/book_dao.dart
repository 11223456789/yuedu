import '../../../model/web_book/web_book.dart';

/// 简化的书籍 DAO（内存实现）
class BookDao {
  final Map<String, Book> _books = {};

  /// 获取所有书籍
  Future<List<Book>> getAllBooks() async => _books.values.toList();

  /// 监听所有书籍（响应式）
  Stream<List<Book>> watchAllBooks() async* {
    yield _books.values.toList();
  }

  /// 按书名搜索
  Future<List<Book>> searchBooks(String keyword) async {
    final lowerKeyword = keyword.toLowerCase();
    return _books.values
        .where((b) =>
            b.name.toLowerCase().contains(lowerKeyword) ||
            b.author.toLowerCase().contains(lowerKeyword))
        .toList();
  }

  /// 按分组获取书籍
  Future<List<Book>> getBooksByGroup(int groupId) async {
    return _books.values.where((b) => b.bookGroup == groupId).toList();
  }

  /// 获取单本书籍
  Future<Book?> getBook(String bookUrl) async => _books[bookUrl];

  /// 插入或更新书籍
  Future<void> insertOrUpdateBook(Book book) async {
    _books[book.bookUrl] = book;
  }

  /// 更新阅读进度
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

  /// 删除书籍
  Future<int> deleteBook(String bookUrl) async {
    final existed = _books.containsKey(bookUrl);
    _books.remove(bookUrl);
    return existed ? 1 : 0;
  }

  /// 删除所有书籍
  Future<int> deleteAllBooks() async {
    final count = _books.length;
    _books.clear();
    return count;
  }

  /// 更新最新章节信息
  Future<void> updateLatestChapter({
    required String bookUrl,
    required String latestChapterTitle,
    required int latestChapterTime,
    required int totalChapterNum,
  }) async {
    final book = _books[bookUrl];
    if (book != null) {
      book.latestChapterTitle = latestChapterTitle;
      book.latestChapterTime = latestChapterTime;
      book.totalChapterNum = totalChapterNum;
    }
  }
}
