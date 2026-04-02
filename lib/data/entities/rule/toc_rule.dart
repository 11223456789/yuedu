import 'dart:convert';

/// 目录规则
class TocRule {
  String? preUpdateJs;
  String? chapterList;
  String? chapterName;
  String? chapterUrl;
  String? formatJs;
  String? isVolume;
  String? isVip;
  String? isPay;
  String? updateTime;
  String? nextTocUrl;

  TocRule({
    this.preUpdateJs,
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.formatJs,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
    this.nextTocUrl,
  });

  TocRule.fromJson(dynamic json) {
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
    preUpdateJs = map['preUpdateJs']?.toString();
    chapterList = map['chapterList']?.toString();
    chapterName = map['chapterName']?.toString();
    chapterUrl = map['chapterUrl']?.toString();
    formatJs = map['formatJs']?.toString();
    isVolume = map['isVolume']?.toString();
    isVip = map['isVip']?.toString();
    isPay = map['isPay']?.toString();
    updateTime = map['updateTime']?.toString();
    nextTocUrl = map['nextTocUrl']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (preUpdateJs != null) map['preUpdateJs'] = preUpdateJs;
    if (chapterList != null) map['chapterList'] = chapterList;
    if (chapterName != null) map['chapterName'] = chapterName;
    if (chapterUrl != null) map['chapterUrl'] = chapterUrl;
    if (formatJs != null) map['formatJs'] = formatJs;
    if (isVolume != null) map['isVolume'] = isVolume;
    if (isVip != null) map['isVip'] = isVip;
    if (isPay != null) map['isPay'] = isPay;
    if (updateTime != null) map['updateTime'] = updateTime;
    if (nextTocUrl != null) map['nextTocUrl'] = nextTocUrl;
    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
