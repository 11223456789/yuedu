import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/book_source_repository.dart';
import '../../data/database/daos/book_source_dao.dart';
import '../../model/web_book/web_book.dart';

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final sourceRepository = ref.watch(bookSourceRepositoryProvider);
  return SearchNotifier(sourceRepository);
});

class SearchState {
  final List<SearchBook> results;
  final List<String> history;
  final bool isSearching;
  final String? error;
  final int completedSources;
  final int totalSources;

  SearchState({
    this.results = const [],
    this.history = const [],
    this.isSearching = false,
    this.error,
    this.completedSources = 0,
    this.totalSources = 0,
  });

  SearchState copyWith({
    List<SearchBook>? results,
    List<String>? history,
    bool? isSearching,
    String? error,
    int? completedSources,
    int? totalSources,
  }) {
    return SearchState(
      results: results ?? this.results,
      history: history ?? this.history,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
      completedSources: completedSources ?? this.completedSources,
      totalSources: totalSources ?? this.totalSources,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final BookSourceRepository _sourceRepository;
  List<StreamSubscription<void>>? _searchSubscriptions;

  SearchNotifier(this._sourceRepository) : super(SearchState());

  /// 执行搜索 - 并发查询所有启用的书源
  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;

    // 取消之前的搜索
    _cancelSearch();

    state = state.copyWith(
      isSearching: true,
      results: [],
      error: null,
      completedSources: 0,
    );

    try {
      // 获取所有启用的书源
      final sources = await _sourceRepository.getEnabledSources();

      if (sources.isEmpty) {
        state = state.copyWith(
          isSearching: false,
          error: '没有可用的书源，请先导入书源',
        );
        return;
      }

      state = state.copyWith(totalSources: sources.length);

      // 添加到搜索历史
      final newHistory = [keyword, ...state.history.where((h) => h != keyword)];
      state = state.copyWith(history: newHistory.take(20).toList());

      // 并发搜索所有书源
      _searchSubscriptions = [];
      int completedCount = 0;

      for (final source in sources) {
        // 检查书源是否有搜索规则
        if (source.searchUrl == null || source.searchUrl!.isEmpty) {
          completedCount++;
          state = state.copyWith(completedSources: completedCount);
          continue;
        }

        // 为每个书源创建独立的搜索任务
        final subscription = Stream.fromFuture(
          _searchSingleSource(source, keyword),
        ).listen(
          (results) {
            if (results.isNotEmpty) {
              state = state.copyWith(
                results: [...state.results, ...results],
              );
            }
          },
          onError: (_) {
            // 单个书源搜索失败，继续其他书源
          },
          onDone: () {
            completedCount++;
            state = state.copyWith(completedSources: completedCount);

            // 所有书源搜索完成
            if (completedCount >= sources.length) {
              state = state.copyWith(isSearching: false);
            }
          },
        );

        _searchSubscriptions!.add(subscription);
      }

      // 设置超时
      Future.delayed(const Duration(seconds: 30), () {
        if (state.isSearching) {
          _cancelSearch();
          state = state.copyWith(isSearching: false);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: '搜索失败: $e',
      );
    }
  }

  /// 搜索单个书源
  Future<List<SearchBook>> _searchSingleSource(
    BookSource source,
    String keyword,
  ) async {
    try {
      return await WebBook.search(source, keyword).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );
    } catch (e) {
      print('书源搜索失败: ${source.bookSourceName}, 错误: $e');
      return [];
    }
  }

  /// 取消当前搜索
  void _cancelSearch() {
    if (_searchSubscriptions != null) {
      for (final sub in _searchSubscriptions!) {
        sub.cancel();
      }
      _searchSubscriptions = null;
    }
  }

  /// 清空搜索历史
  void clearHistory() {
    state = state.copyWith(history: []);
  }

  /// 从历史中删除单个记录
  void removeFromHistory(String keyword) {
    state = state.copyWith(
      history: state.history.where((h) => h != keyword).toList(),
    );
  }

  @override
  void dispose() {
    _cancelSearch();
    super.dispose();
  }
}
