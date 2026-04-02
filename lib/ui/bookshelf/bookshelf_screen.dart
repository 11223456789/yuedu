import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../../data/database/daos/book_dao.dart';
import '../../model/web_book/web_book.dart';
import '../../model/local_book/txt_book.dart';
import '../../model/local_book/epub_book.dart';
import '../../services/book_update_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import '../widgets/book_cover.dart';
import '../search/search_screen.dart';
import '../explore/explore_screen.dart';
import '../settings/settings_screen.dart';
import '../reader/reader_screen.dart';
import 'bookshelf_notifier.dart';

class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  int _currentIndex = 0;
  final BookUpdateService _updateService = BookUpdateService();
  bool _isCheckingUpdate = false;
  List<BookUpdateInfo> _updates = [];

  final List<Widget> _screens = [
    const _BookshelfContent(),
    const SearchScreen(),
    const ExploreScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final bookshelfState = ref.watch(bookshelfNotifierProvider);
    final bookshelfNotifier = ref.read(bookshelfNotifierProvider.notifier);

    return Scaffold(
      appBar: _currentIndex == 0
          ? GoldAppBar(
              title: AppInfo.appName,
              actions: [
                PopupMenuButton<BookshelfViewMode>(
                  icon: Icon(Icons.view_module, color: theme.primary),
                  onSelected: (mode) {
                    bookshelfNotifier.setViewMode(mode);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: BookshelfViewMode.list,
                      child: Text('列表视图'),
                    ),
                    const PopupMenuItem(
                      value: BookshelfViewMode.grid3,
                      child: Text('网格 3 列'),
                    ),
                    const PopupMenuItem(
                      value: BookshelfViewMode.grid4,
                      child: Text('网格 4 列'),
                    ),
                    const PopupMenuItem(
                      value: BookshelfViewMode.grid5,
                      child: Text('网格 5 列'),
                    ),
                    const PopupMenuItem(
                      value: BookshelfViewMode.grid6,
                      child: Text('网格 6 列'),
                    ),
                  ],
                ),
                PopupMenuButton<BookSortType>(
                  icon: Icon(Icons.sort, color: theme.primary),
                  onSelected: (type) {
                    bookshelfNotifier.setSortMode(type);
                  },
                  itemBuilder: (context) => BookSortType.values
                      .map((type) => PopupMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          ))
                      .toList(),
                ),
                IconButton(
                  icon: _isCheckingUpdate
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme.primary),
                          ),
                        )
                      : Badge(
                          isLabelVisible: _updates.isNotEmpty,
                          label: Text('${_updates.length}'),
                          child: Icon(Icons.update, color: theme.primary),
                        ),
                  onPressed: _isCheckingUpdate ? null : _checkUpdates,
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: theme.primary,
              foregroundColor: theme.background,
              onPressed: () {
                _showAddBookDialog(context, theme);
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '书架',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<void> _checkUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    final updates = await _updateService.checkAllBooksUpdate();

    if (mounted) {
      setState(() {
        _isCheckingUpdate = false;
        _updates = updates;
      });

      if (updates.isNotEmpty) {
        _showUpdateDialog(updates);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有书籍都是最新的')),
        );
      }
    }
  }

  void _showUpdateDialog(List<BookUpdateInfo> updates) {
    final theme = ref.read(themeNotifierProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '发现 ${updates.length} 本书有更新',
          style: TextStyle(color: theme.onSurface),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  update.bookName,
                  style: TextStyle(
                    color: theme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '新增 ${update.newChapterCount} 章${update.newChapterTitle != null ? '\n最新: ${update.newChapterTitle}' : ''}',
                  style: TextStyle(color: theme.subText),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final book = await BookDao().getBook(update.bookUrl);
                    if (book != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReaderScreen(
                            book: book,
                            initialChapterIndex: book.durChapterIndex,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    '阅读',
                    style: TextStyle(color: theme.primary),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '关闭',
              style: TextStyle(color: theme.subText),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 更新所有书籍信息
              for (final update in updates) {
                final book = await BookDao().getBook(update.bookUrl);
                if (book != null) {
                  await _updateService.updateBookInfo(book);
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('书籍信息已更新')),
                );
                setState(() {
                  _updates = [];
                });
              }
            },
            child: Text(
              '全部更新',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, AppThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.search, color: theme.primary),
              title: Text(
                '搜索书籍',
                style: TextStyle(color: theme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.file_upload, color: theme.primary),
              title: Text(
                '导入本地书籍',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '支持 TXT、EPUB 格式',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _importLocalBook(context, theme);
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: theme.primary),
              title: Text(
                '从网络导入',
                style: TextStyle(color: theme.onSurface),
              ),
              subtitle: Text(
                '输入书籍链接',
                style: TextStyle(color: theme.subText, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImportFromUrlDialog(context, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importLocalBook(BuildContext context, AppThemeData theme) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      final notifier = ref.read(bookshelfNotifierProvider.notifier);
      int successCount = 0;
      int failCount = 0;

      for (final file in result.files) {
        if (file.path == null) continue;

        try {
          final filePath = file.path!;
          final extension = filePath.split('.').last.toLowerCase();

          if (extension == 'txt') {
            final txtBook = TxtBook(file: File(filePath));
            final book = await txtBook.parseBookInfo();
            await notifier.addBook(book);
            successCount++;
          } else if (extension == 'epub') {
            final epubBook = EpubBook(file: File(filePath));
            final book = await epubBook.parseBookInfo();
            await notifier.addBook(book);
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          print('导入书籍失败: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 $successCount 本书籍${failCount > 0 ? '，失败 $failCount 本' : ''}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  void _showImportFromUrlDialog(BuildContext context, AppThemeData theme) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          '从网络导入',
          style: TextStyle(color: theme.onSurface),
        ),
        content: TextField(
          controller: urlController,
          style: TextStyle(color: theme.onSurface),
          decoration: InputDecoration(
            hintText: '输入书籍链接',
            hintStyle: TextStyle(color: theme.subText),
            filled: true,
            fillColor: theme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
          ),
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
              Navigator.pop(context);
              if (urlController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('正在从网络导入: ${urlController.text}')),
                );
              }
            },
            child: Text(
              '导入',
              style: TextStyle(color: theme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookshelfContent extends ConsumerWidget {
  const _BookshelfContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final state = ref.watch(bookshelfNotifierProvider);
    final notifier = ref.read(bookshelfNotifierProvider.notifier);

    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primary),
      );
    }

    if (state.books.isEmpty) {
      return Container(
        color: theme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                size: 100,
                color: theme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                '书架空空如也',
                style: TextStyle(
                  fontSize: 20,
                  color: theme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '添加书籍开始你的阅读之旅',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.subText,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAddBookDialog(context, theme),
                icon: Icon(Icons.add, color: theme.background),
                label: Text(
                  '添加书籍',
                  style: TextStyle(color: theme.background),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.search, color: theme.primary),
                label: Text(
                  '搜索网络书籍',
                  style: TextStyle(color: theme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.viewMode == BookshelfViewMode.list) {
      return _buildListView(context, state, notifier, theme);
    } else {
      return _buildGridView(context, state, notifier, theme);
    }
  }

  Widget _buildListView(
    BuildContext context,
    BookshelfState state,
    BookshelfNotifier notifier,
    AppThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return _buildBookListItem(context, book, notifier, theme);
      },
    );
  }

  Widget _buildGridView(
    BuildContext context,
    BookshelfState state,
    BookshelfNotifier notifier,
    AppThemeData theme,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: state.viewMode.columns,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.books.length,
      itemBuilder: (context, index) {
        final book = state.books[index];
        return _buildBookGridItem(context, book, notifier, theme);
      },
    );
  }

  Widget _buildBookListItem(
    BuildContext context,
    Book book,
    BookshelfNotifier notifier,
    AppThemeData theme,
  ) {
    // 计算阅读进度
    final double progress = book.totalChapterNum > 0
        ? (book.durChapterIndex / book.totalChapterNum).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: theme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: BookCoverWithProgress(
          coverUrl: book.coverUrl,
          width: 50,
          height: 70,
          progress: progress,
          theme: theme,
          borderRadius: 4,
        ),
        title: Text(
          book.name,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.author,
              style: TextStyle(color: theme.subText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (book.durChapterTitle != null)
              Text(
                '读到: ${book.durChapterTitle}',
                style: TextStyle(color: theme.subText, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: theme.subText),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'read',
              child: Text('开始阅读'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('移除书架'),
            ),
          ],
          onSelected: (value) {
            if (value == 'read') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(
                    book: book,
                    initialChapterIndex: book.durChapterIndex,
                  ),
                ),
              );
            } else if (value == 'delete') {
              notifier.deleteBook(book.bookUrl);
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen(
                book: book,
                initialChapterIndex: book.durChapterIndex,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookGridItem(
    BuildContext context,
    Book book,
    BookshelfNotifier notifier,
    AppThemeData theme,
  ) {
    // 计算阅读进度
    final double progress = book.totalChapterNum > 0
        ? (book.durChapterIndex / book.totalChapterNum).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderScreen(
              book: book,
              initialChapterIndex: book.durChapterIndex,
            ),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: theme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.menu_book, color: theme.primary),
                  title: const Text('开始阅读'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReaderScreen(
                          book: book,
                          initialChapterIndex: book.durChapterIndex,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.error),
                  title: Text('移除书架', style: TextStyle(color: theme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.deleteBook(book.bookUrl);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        color: theme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: BookCoverWithProgress(
                  coverUrl: book.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  progress: progress,
                  theme: theme,
                  borderRadius: 0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.author,
                          style: TextStyle(
                            color: theme.subText,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
