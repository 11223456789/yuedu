import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../model/web_book/web_book.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import 'book_detail_screen.dart';
import 'search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) return;
    final notifier = ref.read(searchNotifierProvider.notifier);
    await notifier.search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '搜索',
      ),
      body: Container(
        color: theme.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.onBackground),
                decoration: InputDecoration(
                  hintText: '输入书名或作者搜索...',
                  hintStyle: TextStyle(color: theme.subText),
                  prefixIcon: Icon(Icons.search, color: theme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.primary),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primary, width: 2),
                  ),
                ),
                onSubmitted: _performSearch,
              ),
            ),
            const GoldDivider(),
            Expanded(
              child: _buildContent(searchState, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState state, AppThemeData theme) {
    if (state.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            Text(
              '搜索中... (${state.completedSources}/${state.totalSources})',
              style: TextStyle(color: theme.subText),
            ),
            const SizedBox(height: 8),
            Text(
              '已找到 ${state.results.length} 个结果',
              style: TextStyle(color: theme.primary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: theme.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.results.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.results.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final book = state.results[index];
          return _buildSearchResultItem(book, theme);
        },
      );
    }

    if (state.history.isNotEmpty) {
      return _buildSearchHistory(state, theme);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '开始搜索书籍',
            style: TextStyle(
              color: theme.subText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入书名或作者名进行搜索',
            style: TextStyle(
              color: theme.subText.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(SearchBook book, AppThemeData theme) {
    return Container(
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
                  book: book,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 80,
                    color: theme.primary.withOpacity(0.2),
                    child: book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.menu_book,
                              color: theme.primary,
                            ),
                          )
                        : Icon(
                            Icons.menu_book,
                            color: theme.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (book.intro != null) ...[
                        const SizedBox(height: 6),
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
                      if (book.origin != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.source,
                              size: 14,
                              color: theme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              book.origin!,
                              style: TextStyle(
                                color: theme.primary,
                                fontSize: 12,
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

  Widget _buildSearchHistory(SearchState state, AppThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchNotifierProvider.notifier).clearHistory();
                },
                child: Text(
                  '清空',
                  style: TextStyle(color: theme.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.history.length,
            separatorBuilder: (context, index) => const GoldDivider(),
            itemBuilder: (context, index) {
              final keyword = state.history[index];
              return ListTile(
                leading: Icon(Icons.history, color: theme.primary),
                title: Text(
                  keyword,
                  style: TextStyle(color: theme.onBackground),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: theme.subText),
                  onPressed: () {
                    ref
                        .read(searchNotifierProvider.notifier)
                        .removeFromHistory(keyword);
                  },
                ),
                onTap: () {
                  _searchController.text = keyword;
                  _performSearch(keyword);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
