import 'dart:convert';

/// 正文处理规则
class ContentRule {
  String? content;
  String? title;
  String? nextContentUrl;
  String? webJs;
  String? sourceRegex;
  String? replaceRegex;
  String? imageStyle;
  String? imageDecode;
  String? payAction;

  ContentRule({
    this.content,
    this.title,
    this.nextContentUrl,
    this.webJs,
    this.sourceRegex,
    this.replaceRegex,
    this.imageStyle,
    this.imageDecode,
    this.payAction,
  });

  ContentRule.fromJson(dynamic json) {
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
    content = map['content']?.toString();
    title = map['title']?.toString();
    nextContentUrl = map['nextContentUrl']?.toString();
    webJs = map['webJs']?.toString();
    sourceRegex = map['sourceRegex']?.toString();
    replaceRegex = map['replaceRegex']?.toString();
    imageStyle = map['imageStyle']?.toString();
    imageDecode = map['imageDecode']?.toString();
    payAction = map['payAction']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (content != null) map['content'] = content;
    if (title != null) map['title'] = title;
    if (nextContentUrl != null) map['nextContentUrl'] = nextContentUrl;
    if (webJs != null) map['webJs'] = webJs;
    if (sourceRegex != null) map['sourceRegex'] = sourceRegex;
    if (replaceRegex != null) map['replaceRegex'] = replaceRegex;
    if (imageStyle != null) map['imageStyle'] = imageStyle;
    if (imageDecode != null) map['imageDecode'] = imageDecode;
    if (payAction != null) map['payAction'] = payAction;
    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
