import 'dart:convert';

/// 书籍详情页规则
class BookInfoRule {
  String? init;
  String? name;
  String? author;
  String? intro;
  String? kind;
  String? lastChapter;
  String? updateTime;
  String? coverUrl;
  String? tocUrl;
  String? wordCount;
  String? canReName;
  String? downloadUrls;

  BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
    this.canReName,
    this.downloadUrls,
  });

  BookInfoRule.fromJson(dynamic json) {
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
    init = map['init']?.toString();
    name = map['name']?.toString();
    author = map['author']?.toString();
    intro = map['intro']?.toString();
    kind = map['kind']?.toString();
    lastChapter = map['lastChapter']?.toString();
    updateTime = map['updateTime']?.toString();
    coverUrl = map['coverUrl']?.toString();
    tocUrl = map['tocUrl']?.toString();
    wordCount = map['wordCount']?.toString();
    canReName = map['canReName']?.toString();
    downloadUrls = map['downloadUrls']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (init != null) map['init'] = init;
    if (name != null) map['name'] = name;
    if (author != null) map['author'] = author;
    if (intro != null) map['intro'] = intro;
    if (kind != null) map['kind'] = kind;
    if (lastChapter != null) map['lastChapter'] = lastChapter;
    if (updateTime != null) map['updateTime'] = updateTime;
    if (coverUrl != null) map['coverUrl'] = coverUrl;
    if (tocUrl != null) map['tocUrl'] = tocUrl;
    if (wordCount != null) map['wordCount'] = wordCount;
    if (canReName != null) map['canReName'] = canReName;
    if (downloadUrls != null) map['downloadUrls'] = downloadUrls;
    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
