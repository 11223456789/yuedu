import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 阅读记录数据类
class ReadRecord {
  final String bookName;
  final String bookAuthor;
  int readTime;
  int lastReadTime;

  ReadRecord({
    required this.bookName,
    required this.bookAuthor,
    required this.readTime,
    required this.lastReadTime,
  });

  factory ReadRecord.fromJson(Map<String, dynamic> json) {
    return ReadRecord(
      bookName: json['bookName'] as String? ?? '',
      bookAuthor: json['bookAuthor'] as String? ?? '',
      readTime: json['readTime'] as int? ?? 0,
      lastReadTime: json['lastReadTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookName': bookName,
      'bookAuthor': bookAuthor,
      'readTime': readTime,
      'lastReadTime': lastReadTime,
    };
  }
}

/// 阅读记录 DAO（使用 SharedPreferences 持久化存储）
class ReadRecordDao {
  static const String _key = 'read_records';
  
  final Map<String, ReadRecord> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(data);
        map.forEach((key, value) {
          _cache[key] = ReadRecord.fromJson(value);
        });
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _cache.forEach((key, value) {
      map[key] = value.toJson();
    });
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<List<ReadRecord>> getAllRecords() async {
    await _ensureLoaded();
    final list = _cache.values.toList();
    list.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
    return list;
  }

  Future<ReadRecord?> getRecord(String bookName) async {
    await _ensureLoaded();
    return _cache[bookName];
  }

  Future<void> addReadTime(String bookName, String author, int seconds) async {
    await _ensureLoaded();
    final existing = _cache[bookName];
    if (existing != null) {
      existing.readTime += seconds;
      existing.lastReadTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      _cache[bookName] = ReadRecord(
        bookName: bookName,
        bookAuthor: author,
        readTime: seconds,
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
      );
    }
    await _save();
  }

  Future<int> deleteRecord(String bookName) async {
    await _ensureLoaded();
    final existed = _cache.containsKey(bookName);
    _cache.remove(bookName);
    if (existed) {
      await _save();
    }
    return existed ? 1 : 0;
  }

  Future<void> clearAll() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
