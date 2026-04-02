import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/enums.dart';
import '../../data/database/daos/search_history_dao.dart';
import '../../model/web_book/web_book.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import '../widgets/gold_app_bar.dart';
import '../widgets/gold_divider.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';
import 'search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchHistoryDao _historyDao = SearchHistoryDao();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchHistory> _histories = [];
  List<SearchHistory> _hotSearches = [];
  List<String> _searchSuggestions = [];
  bool _showHistory = true;
  bool _showSuggestions = false;
  bool _precisionSearch = false;
  Timer? _debounceTimer;
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadHistories();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final text = _searchController.text;
    
    // 取消之前的防抖定时器
    _debounceTimer?.cancel();
    
    if (text.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }
    
    // 防抖处理 - 300ms 后获取搜索建议
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadSearchSuggestions(text);
    });
    
    setState(() {});
  }

  Future<void> _loadSearchSuggestions(String keyword) async {
    if (keyword.isEmpty || keyword.length < 2) return;
    
    setState(() {
      _isLoadingSuggestions = true;
    });
    
    try {
      // 从历史记录中匹配建议
      final histories = await _historyDao.getHistories();
      final suggestions = histories
          .where((h) => h.keyword.toLowerCase().contains(keyword.toLowerCase()))
          .map((h) => h.keyword)
          .take(5)
          .toList();
      
      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty && _searchFocusNode.hasFocus;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _loadHistories() async {
    final histories = await _historyDao.getHistories();
    final hotSearches = await _historyDao.getHotSearches(limit: 10);
    if (mounted) {
      setState(() {
        _histories = histories;
        _hotSearches = hotSearches;
      });
    }
  }

  /// 高亮匹配文本
  Widget _highlightMatch(String text, String query, AppThemeData theme) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(color: theme.onBackground, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: TextStyle(color: theme.onBackground, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: theme.onBackground, fontSize: 14),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              color: theme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) return;

    // 取消防抖定时器
    _debounceTimer?.cancel();
    
    // 隐藏建议
    setState(() {
      _showSuggestions = false;
    });
    
    // 保存搜索历史
    await _historyDao.addHistory(keyword);
    await _loadHistories();

    setState(() {
      _showHistory = false;
    });

    final notifier = ref.read(searchNotifierProvider.notifier);
    await notifier.search(keyword, precision: _precisionSearch);
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
              child: Column(
                children: [
                  // 搜索框
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
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
                                  _showSuggestions = false;
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
                    onTap: () {
                      if (_searchSuggestions.isNotEmpty) {
                        setState(() {
                          _showSuggestions = true;
                        });
                      }
                    },
                  ),
                  // 搜索建议
                  if (_showSuggestions && _searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              '搜索建议',
                              style: TextStyle(
                                color: theme.subText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ..._searchSuggestions.map((suggestion) {
                            return InkWell(
                              onTap: () {
                                _searchController.text = suggestion;
                                _performSearch(suggestion);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 18,
                                      color: theme.subText,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _highlightMatch(suggestion, _searchController.text, theme),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: theme.subText.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // 精确搜索开关
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 16,
                        color: theme.subText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '精确搜索',
                        style: TextStyle(
                          color: theme.subText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _precisionSearch,
                        onChanged: (value) {
                          setState(() {
                            _precisionSearch = value;
                          });
                        },
                        activeColor: theme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Spacer(),
                      if (searchState.isSearching)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(theme.primary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${searchState.completedSources}/${searchState.totalSources}',
                              style: TextStyle(
                                color: theme.subText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
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

    // 显示搜索历史和热门搜索
    if (_showHistory && (_histories.isNotEmpty || _hotSearches.isNotEmpty)) {
      return _buildSearchHistoryAndHot(theme);
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

  Widget _buildSearchHistoryAndHot(AppThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 搜索历史
        if (_histories.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _historyDao.clearAll();
                  await _loadHistories();
                },
                child: Text(
                  '清空',
                  style: TextStyle(color: theme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _histories.take(10).map((history) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = history.keyword;
                  _performSearch(history.keyword);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: theme.subText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        history.keyword,
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () async {
                          await _historyDao.deleteHistory(history.keyword);
                          await _loadHistories();
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: theme.subText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // 热门搜索
        if (_hotSearches.isNotEmpty) ...[
          Text(
            '热门搜索',
            style: TextStyle(
              color: theme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hotSearches.asMap().entries.map((entry) {
              final index = entry.key;
              final history = entry.value;
              return GestureDetector(
                onTap: () {
                  _searchController.text = history.keyword;
                  _performSearch(history.keyword);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: index < 3 ? theme.primary : theme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index < 3 ? theme.background : theme.subText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        history.keyword,
                        style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
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
                BookCover(
                  coverUrl: book.coverUrl,
                  width: 60,
                  height: 80,
                  theme: theme,
                  borderRadius: 8,
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
