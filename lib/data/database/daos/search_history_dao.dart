import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史记录
class SearchHistory {
  final String keyword;
  final int timestamp;
  final int searchCount;

  SearchHistory({
    required this.keyword,
    required this.timestamp,
    this.searchCount = 1,
  });

  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'timestamp': timestamp,
    'searchCount': searchCount,
  };

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    keyword: json['keyword'] ?? '',
    timestamp: json['timestamp'] ?? 0,
    searchCount: json['searchCount'] ?? 1,
  );

  SearchHistory copyWith({
    String? keyword,
    int? timestamp,
    int? searchCount,
  }) => SearchHistory(
    keyword: keyword ?? this.keyword,
    timestamp: timestamp ?? this.timestamp,
    searchCount: searchCount ?? this.searchCount,
  );
}

/// 搜索历史 DAO
class SearchHistoryDao {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryCount = 50; // 最大保存50条记录

  /// 添加搜索历史
  Future<void> addHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final histories = await getHistories();

    // 检查是否已存在
    final index = histories.indexWhere((h) => h.keyword == keyword);
    if (index >= 0) {
      // 更新已有记录
      histories[index] = histories[index].copyWith(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        searchCount: histories[index].searchCount + 1,
      );
    } else {
      // 添加新记录
      histories.add(SearchHistory(
        keyword: keyword,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    // 按时间排序
    histories.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 限制数量
    while (histories.length > _maxHistoryCount) {
      histories.removeLast();
    }

    await prefs.setString(_historyKey, jsonEncode(histories.map((h) => h.toJson()).toList()));
  }

  /// 获取所有搜索历史
  Future<List<SearchHistory>> getHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_historyKey);

    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => SearchHistory.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取热门搜索（按搜索次数排序）
  Future<List<SearchHistory>> getHotSearches({int limit = 10}) async {
    final histories = await getHistories();
    histories.sort((a, b) => b.searchCount.compareTo(a.searchCount));
    return histories.take(limit).toList();
  }

  /// 删除单条历史
  Future<void> deleteHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final histories = await getHistories();
    histories.removeWhere((h) => h.keyword == keyword);
    await prefs.setString(_historyKey, jsonEncode(histories.map((h) => h.toJson()).toList()));
  }

  /// 清空所有历史
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// 搜索历史（根据关键词过滤）
  Future<List<SearchHistory>> searchHistories(String keyword) async {
    final histories = await getHistories();
    if (keyword.isEmpty) return histories;
    return histories.where((h) => h.keyword.contains(keyword)).toList();
  }
}
