import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/daos/book_dao.dart';
import '../../data/database/daos/bookmark_dao.dart';
import '../../model/web_book/web_book.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'reader_screen.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  final String? bookUrl;

  const BookmarkScreen({
    super.key,
    this.bookUrl,
  });

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final BookmarkDao _bookmarkDao = BookmarkDao();
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    final bookmarks = widget.bookUrl != null
        ? await _bookmarkDao.getBookmarksByBook(widget.bookUrl!)
        : await _bookmarkDao.getAllBookmarks();

    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    await _bookmarkDao.deleteBookmark(bookmark);
    await _loadBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书签已删除')),
      );
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}年前';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: widget.bookUrl != null ? '本书书签' : '所有书签',
        actions: [
          if (_bookmarks.isNotEmpty)
            TextButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: theme.surface,
                    title: Text(
                      '确认清空',
                      style: TextStyle(color: theme.onSurface),
                    ),
                    content: Text(
                      '确定要删除所有书签吗？',
                      style: TextStyle(color: theme.subText),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '取消',
                          style: TextStyle(color: theme.subText),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (widget.bookUrl != null) {
                            await _bookmarkDao.deleteBookmarksByBook(widget.bookUrl!);
                          } else {
                            await _bookmarkDao.clearAll();
                          }
                          await _loadBookmarks();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('书签已清空')),
                            );
                          }
                        },
                        child: Text(
                          '确定',
                          style: TextStyle(color: theme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                '清空',
                style: TextStyle(color: theme.error),
              ),
            ),
        ],
      ),
      body: Container(
        color: theme.background,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.primary),
              )
            : _bookmarks.isEmpty
                ? _buildEmptyView(theme)
                : _buildBookmarkList(theme),
      ),
    );
  }

  Widget _buildEmptyView(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: theme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            '暂无书签',
            style: TextStyle(
              fontSize: 18,
              color: theme.subText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '阅读时点击书签按钮添加',
            style: TextStyle(
              fontSize: 14,
              color: theme.subText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkList(AppThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      separatorBuilder: (context, index) => const GoldDivider(),
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        return _buildBookmarkItem(bookmark, theme);
      },
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark, AppThemeData theme) {
    return Dismissible(
      key: Key('${bookmark.bookUrl}_${bookmark.chapterIndex}_${bookmark.chapterPos}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.error,
        child: Icon(
          Icons.delete,
          color: theme.background,
        ),
      ),
      onDismissed: (_) => _deleteBookmark(bookmark),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.bookmark,
            color: theme.primary,
          ),
        ),
        title: Text(
          bookmark.chapterTitle,
          style: TextStyle(
            color: theme.onBackground,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.bookUrl == null)
              Text(
                bookmark.bookName,
                style: TextStyle(
                  color: theme.subText,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              _formatTime(bookmark.createTime),
              style: TextStyle(
                color: theme.subText.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.subText),
          onPressed: () => _deleteBookmark(bookmark),
        ),
        onTap: () async {
          // 获取书籍信息并跳转到阅读页面
          final bookDao = BookDao();
          final book = await bookDao.getBook(bookmark.bookUrl);
          if (book != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(
                  book: book,
                  initialChapterIndex: bookmark.chapterIndex,
                ),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('书籍信息不存在')),
            );
          }
        },
      ),
    );
  }
}
