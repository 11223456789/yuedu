import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 书签数据类
class Bookmark {
  final String bookUrl;
  final String bookName;
  final int chapterIndex;
  final String chapterTitle;
  final int chapterPos;
  final String? content;
  final int createTime;

  Bookmark({
    required this.bookUrl,
    required this.bookName,
    required this.chapterIndex,
    required this.chapterTitle,
    this.chapterPos = 0,
    this.content,
    required this.createTime,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      bookUrl: json['bookUrl'] as String? ?? '',
      bookName: json['bookName'] as String? ?? '',
      chapterIndex: json['chapterIndex'] as int? ?? 0,
      chapterTitle: json['chapterTitle'] as String? ?? '',
      chapterPos: json['chapterPos'] as int? ?? 0,
      content: json['content'] as String?,
      createTime: json['createTime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookUrl': bookUrl,
      'bookName': bookName,
      'chapterIndex': chapterIndex,
      'chapterTitle': chapterTitle,
      'chapterPos': chapterPos,
      'content': content,
      'createTime': createTime,
    };
  }
}

/// 书签 DAO（使用 SharedPreferences 持久化存储）
class BookmarkDao {
  static const String _key = 'bookmarks';
  
  final List<Bookmark> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data);
        _cache.clear();
        for (final item in list) {
          _cache.add(Bookmark.fromJson(item));
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.map((b) => b.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    await _ensureLoaded();
    return List.from(_cache);
  }

  Future<List<Bookmark>> getBookmarksByBook(String bookUrl) async {
    await _ensureLoaded();
    return _cache.where((b) => b.bookUrl == bookUrl).toList();
  }

  Future<void> insertBookmark(Bookmark bookmark) async {
    await _ensureLoaded();
    _cache.add(bookmark);
    await _save();
  }

  Future<void> deleteBookmark(Bookmark bookmark) async {
    await _ensureLoaded();
    _cache.removeWhere((b) => 
      b.bookUrl == bookmark.bookUrl && 
      b.chapterIndex == bookmark.chapterIndex &&
      b.chapterPos == bookmark.chapterPos
    );
    await _save();
  }

  Future<void> deleteBookmarksByBook(String bookUrl) async {
    await _ensureLoaded();
    _cache.removeWhere((b) => b.bookUrl == bookUrl);
    await _save();
  }

  Future<void> clearAll() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
