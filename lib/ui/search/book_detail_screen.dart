import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../../data/database/tables/books_table.dart';
import '../../data/repositories/book_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_border_button.dart';
import '../widgets/gold_divider.dart';
import '../reader/reader_screen.dart';
import 'book_detail_notifier.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String? bookUrl;
  final Book? book;

  const BookDetailScreen({super.key, this.bookUrl, this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _ChapterItem {
  final String title;
  final bool isVolume;
  final bool isVip;
  final bool isPay;

  _ChapterItem({
    required this.title,
    this.isVolume = false,
    this.isVip = false,
    this.isPay = false,
  });
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _isLoading = false;
  Book? _book;
  List<_ChapterItem> _chapters = [];
  bool _isInBookshelf = false;

  @override
  void initState() {
    super.initState();
    _initBook();
  }

  void _initBook() {
    if (widget.book != null) {
      _book = widget.book;
      _isInBookshelf = true;
      _loadSampleChapters();
    } else if (widget.bookUrl != null) {
      _loadBookFromUrl(widget.bookUrl!);
    } else {
      _loadSampleBook();
    }
  }

  Future<void> _loadBookFromUrl(String bookUrl) async {
    final repository = ref.read(bookRepositoryProvider);
    final book = await repository.getBook(bookUrl);
    if (book != null) {
      setState(() {
        _book = book;
        _isInBookshelf = true;
      });
      _loadSampleChapters();
    }
  }

  void _loadSampleBook() {
    setState(() {
      _book = Book(
        bookUrl: 'https://example.com/book/1',
        tocUrl: 'https://example.com/book/1/toc',
        origin: 'sample',
        originName: '示例书源',
        name: '佩宇书屋入门指南',
        author: '佩宇开发组',
        kind: '玄幻',
        coverUrl: null,
        intro: '这是一本介绍如何使用佩宇书屋的示例书籍。佩宇书屋是一款功能强大的跨平台阅读应用，支持自定义书源、多种阅读模式、离线缓存、朗读、RSS 订阅等丰富功能。',
        type: 0,
        bookGroup: 0,
        latestChapterTitle: '第十章 书源高级配置',
        latestChapterTime: DateTime.now().millisecondsSinceEpoch,
        totalChapterNum: 10,
        durChapterTitle: null,
        durChapterIndex: 0,
        durChapterPos: 0,
        durChapterTime: 0,
        canUpdate: true,
        order: 0,
        variable: null,
        readConfig: null,
        customTag: null,
        customCoverUrl: null,
      );
      _isInBookshelf = false;
    });
    _loadSampleChapters();
  }

  void _loadSampleChapters() {
    setState(() {
      _chapters = List.generate(10, (index) => _ChapterItem(
        title: '第 ${index + 1} 章 ${_getChapterTitle(index)}',
        isVolume: index % 5 == 0,
        isVip: index >= 8,
        isPay: index >= 9,
      ));
    });
  }

  String _getChapterTitle(int index) {
    const titles = [
      '初识佩宇书屋',
      '界面介绍',
      '添加书源',
      '搜索书籍',
      '开始阅读',
      '阅读设置',
      '书架管理',
      '备份与恢复',
      '书源进阶',
      '高级配置',
    ];
    return titles[index % titles.length];
  }

  Future<void> _loadChapterList() async {
    if (_book == null) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    _loadSampleChapters();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookshelf() async {
    if (_book == null) return;

    final repository = ref.read(bookRepositoryProvider);

    if (_isInBookshelf) {
      await repository.deleteBook(_book!.bookUrl);
      setState(() {
        _isInBookshelf = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移出书架')),
        );
      }
    } else {
      await repository.saveBook(_book!);
      setState(() {
        _isInBookshelf = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入书架')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '书籍详情',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: theme.background,
        child: _book == null
            ? Center(
                child: Text(
                  '暂无书籍信息',
                  style: TextStyle(color: theme.subText),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildBookInfo(theme),
                  ),
                  const SliverToBoxAdapter(
                    child: GoldDivider(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActions(theme),
                  ),
                  const SliverToBoxAdapter(
                    child: GoldDivider(),
                  ),
                  SliverToBoxAdapter(
                    child: _buildChapterHeader(theme),
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.liujinPrimary,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chapter = _chapters[index];
                          return _buildChapterItem(chapter, theme, index);
                        },
                        childCount: _chapters.length,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookInfo(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 140,
              color: theme.surface,
              child: _book!.coverUrl != null
                  ? Icon(
                      Icons.menu_book,
                      size: 48,
                      color: theme.primary.withOpacity(0.5),
                    )
                  : Icon(
                      Icons.menu_book,
                      size: 48,
                      color: theme.primary.withOpacity(0.5),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _book!.name,
                  style: TextStyle(
                    color: theme.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _book!.author,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 14,
                  ),
                ),
                if (_book!.kind != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: theme.divider),
                    ),
                    child: Text(
                      _book!.kind!,
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                if (_book!.latestChapterTitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '最新章节: ${_book!.latestChapterTitle!}',
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GoldBorderButton(
              text: _isInBookshelf ? '移出书架' : '加入书架',
              filled: !_isInBookshelf,
              onPressed: _toggleBookshelf,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GoldBorderButton(
              text: '开始阅读',
              filled: true,
              onPressed: () {
                if (_book != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderScreen(
                        book: _book!,
                        initialChapterIndex: _book!.durChapterIndex,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterHeader(AppThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '目录',
            style: TextStyle(
              color: theme.onBackground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Text(
                _chapters.isNotEmpty ? '共 ${_chapters.length} 章' : '点击加载目录',
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.primary,
                ),
                onPressed: _loadChapterList,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterItem(
    _ChapterItem chapter,
    AppThemeData theme,
    int index,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_book != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(
                  book: _book!,
                  initialChapterIndex: index,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (chapter.isVolume)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '卷',
                    style: TextStyle(
                      color: theme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  chapter.title,
                  style: TextStyle(
                    color: theme.onBackground,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chapter.isVip || chapter.isPay)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: theme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
