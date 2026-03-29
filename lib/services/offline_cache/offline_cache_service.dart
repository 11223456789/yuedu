
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/books_table.dart';
import '../../data/database/tables/chapters_table.dart';
import '../../model/web_book/web_book.dart';

class OfflineCacheProgress {
  final int total;
  final int current;
  final String currentChapterTitle;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  OfflineCacheProgress({
    required this.total,
    required this.current,
    required this.currentChapterTitle,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
  });

  double get progress =&gt; total &gt; 0 ? current / total : 0.0;
}

class OfflineCacheService {
  final AppDatabase database;
  final WebBook webBook;

  final StreamController&lt;OfflineCacheProgress&gt; _progressController =
      StreamController.broadcast();

  Stream&lt;OfflineCacheProgress&gt; get progressStream =&gt;
      _progressController.stream;

  bool _isCaching = false;
  bool _isCancelled = false;

  OfflineCacheService({
    required this.database,
    required this.webBook,
  });

  bool get isCaching =&gt; _isCaching;

  static const String _chapterContentPrefix = 'chapter_content:';

  String _getChapterContentKey(String bookUrl, int chapterIndex) {
    return '$_chapterContentPrefix$bookUrl:$chapterIndex';
  }

  Future&lt;String?&gt; getCachedChapterContent(
    String bookUrl,
    int chapterIndex,
  ) async {
    final key = _getChapterContentKey(bookUrl, chapterIndex);
    return await database.cacheDao.get(key);
  }

  Future&lt;void&gt; cacheChapterContent(
    String bookUrl,
    int chapterIndex,
    String content, {
    Duration? ttl,
  }) async {
    final key = _getChapterContentKey(bookUrl, chapterIndex);
    await database.cacheDao.put(key, content, ttl: ttl);
  }

  Future&lt;bool&gt; isChapterCached(String bookUrl, int chapterIndex) async {
    final key = _getChapterContentKey(bookUrl, chapterIndex);
    final content = await database.cacheDao.get(key);
    return content != null;
  }

  Future&lt;void&gt; deleteCachedChapter(String bookUrl, int chapterIndex) async {
    final key = _getChapterContentKey(bookUrl, chapterIndex);
    await database.cacheDao.delete(key);
  }

  Future&lt;int&gt; getCachedChaptersCount(String bookUrl) async {
    return 0;
  }

  Future&lt;void&gt; cacheChapters(
    Book book,
    List&lt;Chapter&gt; chapters, {
    int startIndex = 0,
    int? endIndex,
  }) async {
    if (_isCaching) {
      return;
    }

    _isCaching = true;
    _isCancelled = false;

    final actualEndIndex = endIndex ?? chapters.length - 1;
    final chaptersToCache = chapters.sublist(
      startIndex,
      actualEndIndex + 1,
    );

    _progressController.add(OfflineCacheProgress(
      total: chaptersToCache.length,
      current: 0,
      currentChapterTitle: '准备中...',
    ));

    try {
      for (int i = 0; i &lt; chaptersToCache.length; i++) {
        if (_isCancelled) {
          break;
        }

        final chapter = chaptersToCache[i];
        _progressController.add(OfflineCacheProgress(
          total: chaptersToCache.length,
          current: i,
          currentChapterTitle: chapter.title,
        ));

        try {
          final content = await webBook.getContent(
            book.bookUrl,
            chapter,
          );

          if (!_isCancelled) {
            await cacheChapterContent(
              book.bookUrl,
              chapter.chapterIndex,
              content,
            );
          }
        } catch (e) {
          debugPrint('缓存章节失败: ${chapter.title}, 错误: $e');
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_isCancelled) {
        _progressController.add(OfflineCacheProgress(
          total: chaptersToCache.length,
          current: chaptersToCache.length,
          currentChapterTitle: '完成',
          isComplete: true,
        ));
      }
    } catch (e) {
      _progressController.add(OfflineCacheProgress(
        total: chaptersToCache.length,
        current: 0,
        currentChapterTitle: '错误',
        hasError: true,
        errorMessage: e.toString(),
      ));
    } finally {
      _isCaching = false;
    }
  }

  void cancelCaching() {
    _isCancelled = true;
  }

  Future&lt;void&gt; clearBookCache(String bookUrl) async {
  }

  Future&lt;void&gt; clearAllCache() async {
    await database.cacheDao.clearExpired();
  }

  void dispose() {
    _progressController.close();
  }
}
