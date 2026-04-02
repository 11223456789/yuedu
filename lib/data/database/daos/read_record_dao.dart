import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 阅读记录
class ReadRecord {
  final String bookUrl;
  final String bookName;
  final int readTime; // 阅读时长（秒）
  final int readWords; // 阅读字数
  final int lastReadTime; // 最后阅读时间
  final int readCount; // 阅读次数

  ReadRecord({
    required this.bookUrl,
    required this.bookName,
    this.readTime = 0,
    this.readWords = 0,
    this.lastReadTime = 0,
    this.readCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'bookUrl': bookUrl,
    'bookName': bookName,
    'readTime': readTime,
    'readWords': readWords,
    'lastReadTime': lastReadTime,
    'readCount': readCount,
  };

  factory ReadRecord.fromJson(Map<String, dynamic> json) => ReadRecord(
    bookUrl: json['bookUrl'] ?? '',
    bookName: json['bookName'] ?? '',
    readTime: json['readTime'] ?? 0,
    readWords: json['readWords'] ?? 0,
    lastReadTime: json['lastReadTime'] ?? 0,
    readCount: json['readCount'] ?? 0,
  );

  ReadRecord copyWith({
    String? bookUrl,
    String? bookName,
    int? readTime,
    int? readWords,
    int? lastReadTime,
    int? readCount,
  }) => ReadRecord(
    bookUrl: bookUrl ?? this.bookUrl,
    bookName: bookName ?? this.bookName,
    readTime: readTime ?? this.readTime,
    readWords: readWords ?? this.readWords,
    lastReadTime: lastReadTime ?? this.lastReadTime,
    readCount: readCount ?? this.readCount,
  );
}

/// 每日阅读统计
class DailyReadStats {
  final String date; // 日期格式：yyyy-MM-dd
  final int readTime; // 阅读时长（秒）
  final int readWords; // 阅读字数
  final int readCount; // 阅读次数

  DailyReadStats({
    required this.date,
    this.readTime = 0,
    this.readWords = 0,
    this.readCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'readTime': readTime,
    'readWords': readWords,
    'readCount': readCount,
  };

  factory DailyReadStats.fromJson(Map<String, dynamic> json) => DailyReadStats(
    date: json['date'] ?? '',
    readTime: json['readTime'] ?? 0,
    readWords: json['readWords'] ?? 0,
    readCount: json['readCount'] ?? 0,
  );
}

/// 阅读记录 DAO
class ReadRecordDao {
  static const String _recordsKey = 'read_records';
  static const String _dailyStatsKey = 'daily_read_stats';
  static const String _totalStatsKey = 'total_read_stats';

  /// 记录阅读时间
  Future<void> recordReadTime(String bookUrl, String bookName, int seconds, int words) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 更新书籍阅读记录
    final records = await getAllRecords();
    final index = records.indexWhere((r) => r.bookUrl == bookUrl);
    
    if (index >= 0) {
      final record = records[index];
      records[index] = record.copyWith(
        readTime: record.readTime + seconds,
        readWords: record.readWords + words,
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
        readCount: record.readCount + 1,
      );
    } else {
      records.add(ReadRecord(
        bookUrl: bookUrl,
        bookName: bookName,
        readTime: seconds,
        readWords: words,
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
        readCount: 1,
      ));
    }
    
    await prefs.setString(_recordsKey, jsonEncode(records.map((r) => r.toJson()).toList()));
    
    // 更新每日统计
    await _updateDailyStats(seconds, words);
  }

  /// 更新每日统计
  Future<void> _updateDailyStats(int seconds, int words) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _formatDate(DateTime.now());
    
    final stats = await getDailyStats();
    final index = stats.indexWhere((s) => s.date == today);
    
    if (index >= 0) {
      final stat = stats[index];
      stats[index] = DailyReadStats(
        date: today,
        readTime: stat.readTime + seconds,
        readWords: stat.readWords + words,
        readCount: stat.readCount + 1,
      );
    } else {
      stats.add(DailyReadStats(
        date: today,
        readTime: seconds,
        readWords: words,
        readCount: 1,
      ));
    }
    
    // 只保留最近30天的数据
    if (stats.length > 30) {
      stats.sort((a, b) => b.date.compareTo(a.date));
      stats.removeRange(30, stats.length);
    }
    
    await prefs.setString(_dailyStatsKey, jsonEncode(stats.map((s) => s.toJson()).toList()));
  }

  /// 获取所有阅读记录
  Future<List<ReadRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_recordsKey);
    
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => ReadRecord.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取每日统计
  Future<List<DailyReadStats>> getDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_dailyStatsKey);
    
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((j) => DailyReadStats.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取总阅读统计
  Future<Map<String, int>> getTotalStats() async {
    final records = await getAllRecords();
    
    int totalTime = 0;
    int totalWords = 0;
    int totalCount = 0;
    
    for (final record in records) {
      totalTime += record.readTime;
      totalWords += record.readWords;
      totalCount += record.readCount;
    }
    
    return {
      'totalTime': totalTime,
      'totalWords': totalWords,
      'totalCount': totalCount,
      'bookCount': records.length,
    };
  }

  /// 获取今日阅读统计
  Future<DailyReadStats> getTodayStats() async {
    final stats = await getDailyStats();
    final today = _formatDate(DateTime.now());
    
    return stats.firstWhere(
      (s) => s.date == today,
      orElse: () => DailyReadStats(date: today),
    );
  }

  /// 获取本周阅读统计
  Future<Map<String, dynamic>> getWeekStats() async {
    final stats = await getDailyStats();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    int totalTime = 0;
    int totalWords = 0;
    int daysRead = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = _formatDate(date);
      final dayStat = stats.firstWhere(
        (s) => s.date == dateStr,
        orElse: () => DailyReadStats(date: dateStr),
      );
      
      if (dayStat.readTime > 0) {
        totalTime += dayStat.readTime;
        totalWords += dayStat.readWords;
        daysRead++;
      }
    }
    
    return {
      'totalTime': totalTime,
      'totalWords': totalWords,
      'daysRead': daysRead,
      'averageTime': daysRead > 0 ? totalTime ~/ daysRead : 0,
    };
  }

  /// 清空所有记录
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
    await prefs.remove(_dailyStatsKey);
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
