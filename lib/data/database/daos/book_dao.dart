import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 书籍数据类
class Book {
  String bookUrl;
  String tocUrl;
  String origin;
  String originName;
  String name;
  String author;
  String? kind;
  String? customTag;
  String? coverUrl;
  String? customCoverUrl;
  String? intro;
  int type;
  int bookGroup;
  String? latestChapterTitle;
  int latestChapterTime;
  int totalChapterNum;
  String? durChapterTitle;
  int durChapterIndex;
  int durChapterPos;
  int durChapterTime;
  bool canUpdate;
  int order;
  String? variable;
  String? readConfig;

  Book({
    required this.bookUrl,
    this.tocUrl = '',
    this.origin = 'local',
    this.originName = '',
    this.name = '',
    this.author = '',
    this.kind,
    this.customTag,
    this.coverUrl,
    this.customCoverUrl,
    this.intro,
    this.type = 0,
    this.bookGroup = 0,
    this.latestChapterTitle,
    this.latestChapterTime = 0,
    this.totalChapterNum = 0,
    this.durChapterTitle,
    this.durChapterIndex = 0,
    this.durChapterPos = 0,
    this.durChapterTime = 0,
    this.canUpdate = true,
    this.order = 0,
    this.variable,
    this.readConfig,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookUrl: json['bookUrl'] as String? ?? '',
      tocUrl: json['tocUrl'] as String? ?? '',
      origin: json['origin'] as String? ?? 'local',
      originName: json['originName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      author: json['author'] as String? ?? '',
      kind: json['kind'] as String?,
      customTag: json['customTag'] as String?,
      coverUrl: json['coverUrl'] as String?,
      customCoverUrl: json['customCoverUrl'] as String?,
      intro: json['intro'] as String?,
      type: json['type'] as int? ?? 0,
      bookGroup: json['bookGroup'] as int? ?? 0,
      latestChapterTitle: json['latestChapterTitle'] as String?,
      latestChapterTime: json['latestChapterTime'] as int? ?? 0,
      totalChapterNum: json['totalChapterNum'] as int? ?? 0,
      durChapterTitle: json['durChapterTitle'] as String?,
      durChapterIndex: json['durChapterIndex'] as int? ?? 0,
      durChapterPos: json['durChapterPos'] as int? ?? 0,
      durChapterTime: json['durChapterTime'] as int? ?? 0,
      canUpdate: json['canUpdate'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      variable: json['variable'] as String?,
      readConfig: json['readConfig'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookUrl': bookUrl,
      'tocUrl': tocUrl,
      'origin': origin,
      'originName': originName,
      'name': name,
      'author': author,
      'kind': kind,
      'customTag': customTag,
      'coverUrl': coverUrl,
      'customCoverUrl': customCoverUrl,
      'intro': intro,
      'type': type,
      'bookGroup': bookGroup,
      'latestChapterTitle': latestChapterTitle,
      'latestChapterTime': latestChapterTime,
      'totalChapterNum': totalChapterNum,
      'durChapterTitle': durChapterTitle,
      'durChapterIndex': durChapterIndex,
      'durChapterPos': durChapterPos,
      'durChapterTime': durChapterTime,
      'canUpdate': canUpdate,
      'order': order,
      'variable': variable,
      'readConfig': readConfig,
    };
  }

  Book copyWith({
    String? bookUrl,
    String? tocUrl,
    String? origin,
    String? originName,
    String? name,
    String? author,
    String? kind,
    String? customTag,
    String? coverUrl,
    String? customCoverUrl,
    String? intro,
    int? type,
    int? bookGroup,
    String? latestChapterTitle,
    int? latestChapterTime,
    int? totalChapterNum,
    String? durChapterTitle,
    int? durChapterIndex,
    int? durChapterPos,
    int? durChapterTime,
    bool? canUpdate,
    int? order,
    String? variable,
    String? readConfig,
  }) {
    return Book(
      bookUrl: bookUrl ?? this.bookUrl,
      tocUrl: tocUrl ?? this.tocUrl,
      origin: origin ?? this.origin,
      originName: originName ?? this.originName,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      customTag: customTag ?? this.customTag,
      coverUrl: coverUrl ?? this.coverUrl,
      customCoverUrl: customCoverUrl ?? this.customCoverUrl,
      intro: intro ?? this.intro,
      type: type ?? this.type,
      bookGroup: bookGroup ?? this.bookGroup,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      latestChapterTime: latestChapterTime ?? this.latestChapterTime,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      durChapterTitle: durChapterTitle ?? this.durChapterTitle,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      durChapterPos: durChapterPos ?? this.durChapterPos,
      durChapterTime: durChapterTime ?? this.durChapterTime,
      canUpdate: canUpdate ?? this.canUpdate,
      order: order ?? this.order,
      variable: variable ?? this.variable,
      readConfig: readConfig ?? this.readConfig,
    );
  }
}

/// 书籍 DAO（使用 SharedPreferences 持久化存储）
class BookDao {
  static const String _key = 'books';
  
  final Map<String, Book> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(data);
        map.forEach((key, value) {
          _cache[key] = Book.fromJson(value);
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

  Future<List<Book>> getAllBooks() async {
    await _ensureLoaded();
    return _cache.values.toList();
  }

  Stream<List<Book>> watchAllBooks() async* {
    await _ensureLoaded();
    yield _cache.values.toList();
  }

  Future<List<Book>> searchBooks(String keyword) async {
    await _ensureLoaded();
    final lowerKeyword = keyword.toLowerCase();
    return _cache.values
        .where((b) =>
            b.name.toLowerCase().contains(lowerKeyword) ||
            b.author.toLowerCase().contains(lowerKeyword))
        .toList();
  }

  Future<List<Book>> getBooksByGroup(int groupId) async {
    await _ensureLoaded();
    return _cache.values.where((b) => b.bookGroup == groupId).toList();
  }

  Future<Book?> getBook(String bookUrl) async {
    await _ensureLoaded();
    return _cache[bookUrl];
  }

  Future<void> insertOrUpdateBook(Book book) async {
    await _ensureLoaded();
    _cache[book.bookUrl] = book;
    await _save();
  }

  Future<void> updateBook(Book book) async {
    await insertOrUpdateBook(book);
  }

  Future<void> updateReadProgress({
    required String bookUrl,
    required int chapterIndex,
    required int chapterPos,
    required String chapterTitle,
  }) async {
    await _ensureLoaded();
    final book = _cache[bookUrl];
    if (book != null) {
      book.durChapterIndex = chapterIndex;
      book.durChapterPos = chapterPos;
      book.durChapterTitle = chapterTitle;
      book.durChapterTime = DateTime.now().millisecondsSinceEpoch;
      await _save();
    }
  }

  Future<int> deleteBook(String bookUrl) async {
    await _ensureLoaded();
    final existed = _cache.containsKey(bookUrl);
    _cache.remove(bookUrl);
    if (existed) {
      await _save();
    }
    return existed ? 1 : 0;
  }

  Future<int> deleteAllBooks() async {
    await _ensureLoaded();
    final count = _cache.length;
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    return count;
  }

  Future<void> updateLatestChapter({
    required String bookUrl,
    required String latestChapterTitle,
    required int latestChapterTime,
    required int totalChapterNum,
  }) async {
    await _ensureLoaded();
    final book = _cache[bookUrl];
    if (book != null) {
      book.latestChapterTitle = latestChapterTitle;
      book.latestChapterTime = latestChapterTime;
      book.totalChapterNum = totalChapterNum;
      await _save();
    }
  }
}
