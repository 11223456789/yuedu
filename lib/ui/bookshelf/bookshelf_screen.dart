import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../constants/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
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
                // TODO: 实现添加书籍功能
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
                size: 80,
                color: theme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                '书架',
                style: TextStyle(
                  fontSize: 24,
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '添加书籍开始阅读吧',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.subText,
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
    return Card(
      color: theme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 50,
            height: 70,
            color: theme.primary.withOpacity(0.2),
            child: Icon(
              Icons.menu_book,
              color: theme.primary,
            ),
          ),
        ),
        title: Text(
          book.name,
          style: TextStyle(
            color: theme.text,
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
                child: Container(
                  color: theme.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.menu_book,
                    color: theme.primary,
                    size: 40,
                  ),
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
                      color: theme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: TextStyle(
                      color: theme.subText,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
