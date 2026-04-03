import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_dao.dart' show Book, BookChapter;
import '../../data/database/daos/book_source_dao.dart' show BookSource;
import '../../data/database/daos/bookmark_dao.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/repositories/book_source_repository.dart';
import '../../model/web_book/web_book.dart' show SearchBook;

/// 章节内容状态
class ChapterContent {
  final String content;
  final String title;
  final bool isLoading;
  final String? error;

  const ChapterContent({
    this.content = '',
    this.title = '',
    this.isLoading = false,
    this.error,
  });

  ChapterContent copyWith({
    String? content,
    String? title,
    bool? isLoading,
    String? error,
  }) {
    return ChapterContent(
      content: content ?? this.content,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 阅读器状态
class ReaderState {
  final Book book;
  final BookSource? source;
  final List<BookChapter> chapters;
  final int currentChapterIndex;
  final ChapterContent currentContent;
  final bool isLoadingChapters;
  final String? error;

  ReaderState({
    required this.book,
    this.source,
    this.chapters = const [],
    this.currentChapterIndex = 0,
    this.currentContent = const ChapterContent(),
    this.isLoadingChapters = false,
    this.error,
  });

  ReaderState copyWith({
    Book? book,
    BookSource? source,
    List<BookChapter>? chapters,
    int? currentChapterIndex,
    ChapterContent? currentContent,
    bool? isLoadingChapters,
    String? error,
  }) {
    return ReaderState(
      book: book ?? this.book,
      source: source ?? this.source,
      chapters: chapters ?? this.chapters,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentContent: currentContent ?? this.currentContent,
      isLoadingChapters: isLoadingChapters ?? this.isLoadingChapters,
      error: error ?? this.error,
    );
  }
}

/// 阅读器状态管理
class ReaderNotifier extends StateNotifier<ReaderState> {
  final BookRepository _bookRepository;
  final BookSourceRepository _sourceRepository;

  ReaderNotifier({
    required Book book,
    required BookRepository bookRepository,
    required BookSourceRepository sourceRepository,
  })  : _bookRepository = bookRepository,
        _sourceRepository = sourceRepository,
        super(ReaderState(book: book)) {
    _init();
  }

  Future<void> _init() async {
    await _loadSource();
    await _loadChapters();
    await _loadChapterContent(state.currentChapterIndex);
  }

  /// 加载书源
  Future<void> _loadSource() async {
    final origin = state.book.origin;
    if (origin == 'local' || origin.isEmpty) {
      return;
    }

    final source = await _sourceRepository.getSource(origin);
    if (source != null) {
      state = state.copyWith(source: source);
    }
  }

  /// 加载章节目录
  Future<void> _loadChapters() async {
    if (state.source == null) {
      // 本地书籍，使用模拟章节
      state = state.copyWith(
        chapters: List.generate(
          50,
          (i) => BookChapter(
            url: '',
            bookUrl: state.book.bookUrl,
            title: '第${i + 1}章',
            index: i,
          ),
        ),
      );
      return;
    }

    state = state.copyWith(isLoadingChapters: true);

    try {
      final chapters = await WebBook.getChapterList(
        state.source!,
        state.book,
      );
      state = state.copyWith(
        chapters: chapters,
        isLoadingChapters: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingChapters: false,
        error: '加载目录失败: $e',
      );
    }
  }

  /// 章节内容缓存管理
  final Map<int, String> _contentCache = {};
  static const int _maxCacheSize = 10; // 最大缓存章节数
  final List<int> _cacheOrder = []; // 缓存访问顺序

  /// 获取缓存内容
  String? _getCachedContent(int index) {
    if (_contentCache.containsKey(index)) {
      // 更新访问顺序
      _cacheOrder.remove(index);
      _cacheOrder.add(index);
      return _contentCache[index];
    }
    return null;
  }

  /// 添加缓存内容
  void _addToCache(int index, String content) {
    // 如果缓存已满，移除最旧的
    if (_contentCache.length >= _maxCacheSize && !_contentCache.containsKey(index)) {
      final oldestIndex = _cacheOrder.removeAt(0);
      _contentCache.remove(oldestIndex);
    }
    
    _contentCache[index] = content;
    if (!_cacheOrder.contains(index)) {
      _cacheOrder.add(index);
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (index < 0 || index >= state.chapters.length) return;

    final chapter = state.chapters[index];

    // 检查缓存
    final cachedContent = _getCachedContent(index);
    if (cachedContent != null) {
      state = state.copyWith(
        currentChapterIndex: index,
        currentContent: ChapterContent(
          content: cachedContent,
          title: chapter.title,
          isLoading: false,
        ),
      );
      // 更新阅读进度
      await _bookRepository.updateReadProgress(
        bookUrl: state.book.bookUrl,
        chapterIndex: index,
        chapterPos: 0,
        chapterTitle: chapter.title,
      );
      // 预加载相邻章节
      _preloadAdjacentChapters(index);
      return;
    }

    state = state.copyWith(
      currentChapterIndex: index,
      currentContent: ChapterContent(
        title: chapter.title,
        isLoading: true,
      ),
    );

    try {
      String content;
      if (state.source != null) {
        content = await WebBook.getContent(
          state.source!,
          state.book,
          chapter,
        );
      } else {
        // 本地书籍的模拟内容
        content = '''这是 ${chapter.title} 的内容。

在实际应用中，这里会显示从书源获取到的章节正文。

佩宇书屋是一个基于 Flutter 开发的跨平台阅读应用，支持多种书源解析方式。

阅读界面支持多种自定义设置，包括字体大小、行间距、背景颜色等。

...''';
      }

      // 缓存内容
      _addToCache(index, content);

      state = state.copyWith(
        currentContent: ChapterContent(
          content: content,
          title: chapter.title,
          isLoading: false,
        ),
      );

      // 更新阅读进度
      await _bookRepository.updateReadProgress(
        bookUrl: state.book.bookUrl,
        chapterIndex: index,
        chapterPos: 0,
        chapterTitle: chapter.title,
      );

      // 预加载相邻章节
      _preloadAdjacentChapters(index);
    } catch (e) {
      state = state.copyWith(
        currentContent: ChapterContent(
          title: chapter.title,
          isLoading: false,
          error: '加载失败: $e',
        ),
      );
    }
  }

  /// 预加载相邻章节（上一章和下一章）
  Future<void> _preloadAdjacentChapters(int currentIndex) async {
    if (state.source == null) return;

    final preloadIndexes = [currentIndex - 1, currentIndex + 1];
    
    for (final index in preloadIndexes) {
      if (index >= 0 && 
          index < state.chapters.length && 
          !_contentCache.containsKey(index)) {
        _preloadChapter(index);
      }
    }
  }

  /// 预加载单个章节
  Future<void> _preloadChapter(int index) async {
    try {
      final chapter = state.chapters[index];
      final content = await WebBook.getContent(
        state.source!,
        state.book,
        chapter,
      ).timeout(const Duration(seconds: 10));
      _addToCache(index, content);
    } catch (e) {
      // 预加载失败不处理
    }
  }

  /// 清除缓存
  void clearCache() {
    _contentCache.clear();
    _cacheOrder.clear();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedCount': _contentCache.length,
      'maxCacheSize': _maxCacheSize,
      'cachedIndexes': _cacheOrder.toList(),
    };
  }

  /// 跳转到指定章节
  Future<void> goToChapter(int index) async {
    await _loadChapterContent(index);
  }

  /// 下一章
  Future<void> nextChapter() async {
    if (state.currentChapterIndex < state.chapters.length - 1) {
      await _loadChapterContent(state.currentChapterIndex + 1);
    }
  }

  /// 上一章
  Future<void> previousChapter() async {
    if (state.currentChapterIndex > 0) {
      await _loadChapterContent(state.currentChapterIndex - 1);
    }
  }

  /// 添加书签
  Future<void> addBookmark() async {
    final bookmark = Bookmark(
      bookUrl: state.book.bookUrl,
      bookName: state.book.name,
      chapterIndex: state.currentChapterIndex,
      chapterTitle: state.currentContent.title,
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    final dao = BookmarkDao();
    await dao.insertBookmark(bookmark);
  }
}

/// Provider
final readerNotifierProvider = StateNotifierProvider.family<ReaderNotifier, ReaderState, Book>(
  (ref, book) {
    final bookRepository = ref.watch(bookRepositoryProvider);
    final sourceRepository = ref.watch(bookSourceRepositoryProvider);
    return ReaderNotifier(
      book: book,
      bookRepository: bookRepository,
      sourceRepository: sourceRepository,
    );
  },
);
