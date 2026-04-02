import 'dart:async';
import '../data/database/daos/book_dao.dart';
import '../data/database/daos/book_source_dao.dart';
import '../data/repositories/book_source_repository.dart';
import '../model/web_book/web_book.dart';

/// 书籍更新信息
class BookUpdateInfo {
  final String bookUrl;
  final String bookName;
  final String? newChapterTitle;
  final int newChapterCount;
  final bool hasUpdate;

  BookUpdateInfo({
    required this.bookUrl,
    required this.bookName,
    this.newChapterTitle,
    required this.newChapterCount,
    required this.hasUpdate,
  });
}

/// 书籍更新服务
class BookUpdateService {
  final BookDao _bookDao = BookDao();
  final BookSourceRepository _sourceRepository = BookSourceRepository();

  /// 检查单本书籍是否有更新
  Future<BookUpdateInfo?> checkBookUpdate(Book book) async {
    try {
      // 获取书源
      final source = await _sourceRepository.getSource(book.origin);
      if (source == null) return null;

      // 获取最新书籍信息
      final updatedBook = await WebBook.getBookInfo(source, book);

      // 检查是否有新章节
      final currentChapterNum = book.totalChapterNum;
      final newChapterNum = updatedBook.totalChapterNum;

      if (newChapterNum > currentChapterNum) {
        return BookUpdateInfo(
          bookUrl: book.bookUrl,
          bookName: book.name,
          newChapterTitle: updatedBook.latestChapterTitle,
          newChapterCount: newChapterNum - currentChapterNum,
          hasUpdate: true,
        );
      }

      return BookUpdateInfo(
        bookUrl: book.bookUrl,
        bookName: book.name,
        hasUpdate: false,
        newChapterCount: 0,
      );
    } catch (e) {
      print('检查书籍更新失败: ${book.name}, 错误: $e');
      return null;
    }
  }

  /// 检查所有书籍更新
  Future<List<BookUpdateInfo>> checkAllBooksUpdate() async {
    final books = await _bookDao.getAllBooks();
    final List<BookUpdateInfo> updates = [];

    for (final book in books) {
      // 只检查网络书籍
      if (book.type == 0) {
        final updateInfo = await checkBookUpdate(book);
        if (updateInfo != null && updateInfo.hasUpdate) {
          updates.add(updateInfo);
        }
      }
    }

    return updates;
  }

  /// 更新书籍信息
  Future<void> updateBookInfo(Book book) async {
    try {
      final source = await _sourceRepository.getSource(book.origin);
      if (source == null) return;

      // 获取最新书籍信息
      final updatedBook = await WebBook.getBookInfo(source, book);

      // 获取最新目录
      final chapters = await WebBook.getChapterList(source, updatedBook);

      // 更新书籍信息
      final bookToUpdate = updatedBook.copyWith(
        totalChapterNum: chapters.length,
        latestChapterTime: DateTime.now().millisecondsSinceEpoch,
      );

      await _bookDao.updateBook(bookToUpdate);
    } catch (e) {
      print('更新书籍信息失败: ${book.name}, 错误: $e');
    }
  }
}

/// 更新检查定时器
class UpdateChecker {
  Timer? _timer;
  final BookUpdateService _updateService = BookUpdateService();
  final Function(List<BookUpdateInfo>)? onUpdateFound;

  UpdateChecker({this.onUpdateFound});

  /// 开始定时检查
  void start({Duration interval = const Duration(hours: 1)}) {
    stop();
    _timer = Timer.periodic(interval, (_) async {
      await checkUpdates();
    });
    // 立即执行一次检查
    checkUpdates();
  }

  /// 停止定时检查
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 手动检查更新
  Future<List<BookUpdateInfo>> checkUpdates() async {
    final updates = await _updateService.checkAllBooksUpdate();
    if (updates.isNotEmpty && onUpdateFound != null) {
      onUpdateFound!(updates);
    }
    return updates;
  }
}
