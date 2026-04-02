import 'dart:convert';

/// 搜索结果处理规则
class SearchRule {
  String? checkKeyWord;
  String? bookList;
  String? name;
  String? author;
  String? intro;
  String? kind;
  String? lastChapter;
  String? updateTime;
  String? bookUrl;
  String? coverUrl;
  String? wordCount;

  SearchRule({
    this.checkKeyWord,
    this.bookList,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.bookUrl,
    this.coverUrl,
    this.wordCount,
  });

  SearchRule.fromJson(dynamic json) {
    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map) {
          _fromMap(decoded);
        }
      } catch (_) {}
    } else if (json is Map) {
      _fromMap(json);
    }
  }

  void _fromMap(Map<dynamic, dynamic> map) {
    checkKeyWord = map['checkKeyWord']?.toString();
    bookList = map['bookList']?.toString();
    name = map['name']?.toString();
    author = map['author']?.toString();
    intro = map['intro']?.toString();
    kind = map['kind']?.toString();
    lastChapter = map['lastChapter']?.toString();
    updateTime = map['updateTime']?.toString();
    bookUrl = map['bookUrl']?.toString();
    coverUrl = map['coverUrl']?.toString();
    wordCount = map['wordCount']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (checkKeyWord != null) map['checkKeyWord'] = checkKeyWord;
    if (bookList != null) map['bookList'] = bookList;
    if (name != null) map['name'] = name;
    if (author != null) map['author'] = author;
    if (intro != null) map['intro'] = intro;
    if (kind != null) map['kind'] = kind;
    if (lastChapter != null) map['lastChapter'] = lastChapter;
    if (updateTime != null) map['updateTime'] = updateTime;
    if (bookUrl != null) map['bookUrl'] = bookUrl;
    if (coverUrl != null) map['coverUrl'] = coverUrl;
    if (wordCount != null) map['wordCount'] = wordCount;
    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
