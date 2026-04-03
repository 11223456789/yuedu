import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_source_dao.dart' show BookSource;
import '../../model/web_book/web_book.dart' show SearchBook, WebBook;
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../search/book_detail_screen.dart';
import 'explore_screen.dart';

/// 发现分类详情页 - 展示某个分类下的书籍列表
class ExploreKindScreen extends ConsumerStatefulWidget {
  final BookSource source;
  final ExploreKind kind;

  const ExploreKindScreen({
    super.key,
    required this.source,
    required this.kind,
  });

  @override
  ConsumerState<ExploreKindScreen> createState() => _ExploreKindScreenState();
}

class _ExploreKindScreenState extends ConsumerState<ExploreKindScreen> {
  bool _isLoading = true;
  List<SearchBook> _books = [];
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreBooks();
      }
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      // 使用发现URL获取书籍列表
      // 发现URL通常包含分页参数，如 {{page}}
      final books = await WebBook.explore(
        widget.source,
        widget.kind.url,
        page: _currentPage,
      );

      setState(() {
        _books = books;
        _isLoading = false;
        _hasMore = books.length >= 20; // 如果返回20条，可能还有更多
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final books = await WebBook.explore(
        widget.source,
        widget.kind.url,
        page: _currentPage + 1,
      );

      setState(() {
        if (books.isNotEmpty) {
          _books.addAll(books);
          _currentPage++;
        }
        _hasMore = books.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.kind.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(AppThemeData theme) {
    if (_isLoading && _books.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    if (_error != null && _books.isEmpty) {
      return _buildErrorView(theme);
    }

    if (_books.isEmpty) {
      return _buildEmptyView(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      color: theme.primary,
      backgroundColor: theme.surface,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _books.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _books.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(color: theme.primary),
              ),
            );
          }
          final book = _books[index];
          return _buildBookItem(book, theme);
        },
      ),
    );
  }

  Widget _buildErrorView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.error),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(color: theme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBooks,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: theme.subText,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无书籍',
            style: TextStyle(
              color: theme.subText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '该分类下暂时没有书籍',
            style: TextStyle(
              color: theme.subText.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem(SearchBook book, AppThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(
                  searchBook: book,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.book,
                              color: theme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.book,
                          color: theme.primary,
                          size: 40,
                        ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 13,
                        ),
                      ),
                      if (book.intro != null && book.intro!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          book.intro!,
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (book.lastChapter != null && book.lastChapter!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                book.lastChapter!,
                                style: TextStyle(
                                  color: theme.primary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
