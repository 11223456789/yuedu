import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';

class BookmarkItem {
  final int time;
  final String bookUrl;
  final String bookName;
  final int chapterIndex;
  final int chapterPos;
  final String chapterName;
  final String content;
  final int? color;

  BookmarkItem({
    required this.time,
    required this.bookUrl,
    required this.bookName,
    required this.chapterIndex,
    required this.chapterPos,
    required this.chapterName,
    required this.content,
    this.color,
  });

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class BookmarkListScreen extends ConsumerStatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  final List<BookmarkItem> _bookmarks = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedBookmarks = {};

  @override
  void initState() {
    super.initState();
    _loadMockBookmarks();
  }

  void _loadMockBookmarks() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _bookmarks.addAll([
      BookmarkItem(
        time: now - 86400000,
        bookUrl: 'https://example.com/book1',
        bookName: '斗破苍穹',
        chapterIndex: 125,
        chapterPos: 0,
        chapterName: '第125章 突破',
        content: '萧炎深吸一口气，感受着体内那蓬勃的斗气...',
        color: 0xFFFFD700,
      ),
      BookmarkItem(
        time: now - 172800000,
        bookUrl: 'https://example.com/book2',
        bookName: '完美世界',
        chapterIndex: 89,
        chapterPos: 150,
        chapterName: '第89章 激战',
        content: '石昊一声大喝，双拳轰出，虚空都在颤抖...',
      ),
      BookmarkItem(
        time: now - 259200000,
        bookUrl: 'https://example.com/book1',
        bookName: '斗破苍穹',
        chapterIndex: 100,
        chapterPos: 50,
        chapterName: '第100章 神秘老者',
        content: '就在这时，一道苍老的声音在萧炎脑海中响起...',
      ),
    ]);
  }

  void _toggleBookmarkSelection(int index) {
    setState(() {
      if (_selectedBookmarks.contains(index)) {
        _selectedBookmarks.remove(index);
        if (_selectedBookmarks.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedBookmarks.add(index);
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedBookmarks.add(index);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookmarks.clear();
    });
  }

  void _deleteSelectedBookmarks() {
    final theme = ref.read(themeNotifierProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '确认删除',
          style: TextStyle(color: theme.onSurface),
        ),
        content: Text(
          '确定要删除选中的 ${_selectedBookmarks.length} 个书签吗？',
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
            onPressed: () {
              final sortedIndices = _selectedBookmarks.toList()..sort((a, b) => b.compareTo(a));
              for (final index in sortedIndices) {
                _bookmarks.removeAt(index);
              }
              _exitSelectionMode();
              Navigator.pop(context);
            },
            child: Text(
              '删除',
              style: TextStyle(color: theme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _openBookmark(BookmarkItem bookmark) {
    // TODO: 跳转到阅读界面并定位到书签位置
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开书签: ${bookmark.bookName} - ${bookmark.chapterName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: theme.surface,
              leading: IconButton(
                icon: Icon(Icons.close, color: theme.onSurface),
                onPressed: _exitSelectionMode,
              ),
              title: Text(
                '已选择 ${_selectedBookmarks.length} 个',
                style: TextStyle(color: theme.onSurface),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  onPressed: _deleteSelectedBookmarks,
                ),
              ],
            )
          : GoldAppBar(
              title: '书签管理',
            ),
      body: Container(
        color: theme.background,
        child: _bookmarks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: theme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无书签',
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '在阅读界面添加书签',
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _bookmarks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bookmark = _bookmarks[index];
                  final isSelected = _selectedBookmarks.contains(index);
                  return _buildBookmarkItem(bookmark, index, isSelected, theme);
                },
              ),
      ),
    );
  }

  Widget _buildBookmarkItem(
    BookmarkItem bookmark,
    int index,
    bool isSelected,
    AppThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.primary.withOpacity(0.2) : theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.primary : theme.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode
              ? () => _toggleBookmarkSelection(index)
              : () => _openBookmark(bookmark),
          onLongPress: () => _enterSelectionMode(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (bookmark.color != null)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(bookmark.color!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    if (bookmark.color != null) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookmark.bookName,
                        style: TextStyle(
                          color: theme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      bookmark.formattedTime,
                      style: TextStyle(
                        color: theme.subText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bookmark.chapterName,
                  style: TextStyle(
                    color: theme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  bookmark.content,
                  style: TextStyle(
                    color: theme.subText,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
