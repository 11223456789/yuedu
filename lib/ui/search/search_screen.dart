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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<SearchBook> _searchResults = [];
  bool _isSearching = false;
  final List<String> _searchHistory = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    // TODO: 从数据库获取启用的书源并并发搜索
    // 这里暂时模拟搜索
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSearching = false;
        // 添加模拟搜索结果
        _searchHistory.insert(0, keyword);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: GoldAppBar(
        title: '搜索',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                            setState(() {
                              _searchResults.clear();
                            });
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
              child: _isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primary),
                          const SizedBox(height: 16),
                          Text(
                            '搜索中...',
                            style: TextStyle(color: theme.subText),
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final book = _searchResults[index];
                            return _buildSearchResultItem(book, theme);
                          },
                        )
                      : _searchHistory.isNotEmpty
                          ? _buildSearchHistory(theme)
                          : Center(
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
                                ],
                              ),
                            ),
            ),
          ],
        ),
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
                builder: (context) => const BookDetailScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.coverUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 80,
                      color: theme.divider,
                      child: Icon(
                        Icons.menu_book,
                        color: theme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                if (book.coverUrl != null) const SizedBox(width: 12),
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

  Widget _buildSearchHistory(AppThemeData theme) {
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
                  setState(() {
                    _searchHistory.clear();
                  });
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
            itemCount: _searchHistory.length,
            separatorBuilder: (context, index) => const GoldDivider(),
            itemBuilder: (context, index) {
              final keyword = _searchHistory[index];
              return ListTile(
                leading: Icon(Icons.history, color: theme.primary),
                title: Text(
                  keyword,
                  style: TextStyle(color: theme.onBackground),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: theme.subText),
                  onPressed: () {
                    setState(() {
                      _searchHistory.removeAt(index);
                    });
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
