import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// RSS源数据类
class RssSource {
  String sourceUrl;
  String sourceName;
  String? sourceIcon;
  String? sourceGroup;
  String? sourceComment;
  bool enabled;
  String? variableComment;
  String? jsLib;
  bool enabledCookieJar;
  String? concurrentRate;
  String? header;
  String? loginUrl;
  String? loginUi;
  String? loginCheckJs;
  String? coverDecodeJs;
  String? sortUrl;
  bool singleUrl;
  int articleStyle;
  String? ruleArticles;
  String? ruleNextPage;
  String? ruleTitle;
  String? rulePubDate;
  String? ruleDescription;
  String? ruleImage;
  String? ruleLink;
  String? ruleContent;
  String? contentWhitelist;
  String? contentBlacklist;
  String? shouldOverrideUrlLoading;
  String? style;
  bool enableJs;
  bool loadWithBaseUrl;
  String? injectJs;
  int lastUpdateTime;
  int customOrder;

  RssSource({
    required this.sourceUrl,
    required this.sourceName,
    this.sourceIcon,
    this.sourceGroup,
    this.sourceComment,
    this.enabled = true,
    this.variableComment,
    this.jsLib,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.sortUrl,
    this.singleUrl = false,
    this.articleStyle = 0,
    this.ruleArticles,
    this.ruleNextPage,
    this.ruleTitle,
    this.rulePubDate,
    this.ruleDescription,
    this.ruleImage,
    this.ruleLink,
    this.ruleContent,
    this.contentWhitelist,
    this.contentBlacklist,
    this.shouldOverrideUrlLoading,
    this.style,
    this.enableJs = true,
    this.loadWithBaseUrl = true,
    this.injectJs,
    this.lastUpdateTime = 0,
    this.customOrder = 0,
  });

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      sourceUrl: json['sourceUrl'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceIcon: json['sourceIcon'] as String?,
      sourceGroup: json['sourceGroup'] as String?,
      sourceComment: json['sourceComment'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      variableComment: json['variableComment'] as String?,
      jsLib: json['jsLib'] as String?,
      enabledCookieJar: json['enabledCookieJar'] as bool? ?? true,
      concurrentRate: json['concurrentRate'] as String?,
      header: json['header'] as String?,
      loginUrl: json['loginUrl'] as String?,
      loginUi: json['loginUi'] as String?,
      loginCheckJs: json['loginCheckJs'] as String?,
      coverDecodeJs: json['coverDecodeJs'] as String?,
      sortUrl: json['sortUrl'] as String?,
      singleUrl: json['singleUrl'] as bool? ?? false,
      articleStyle: json['articleStyle'] as int? ?? 0,
      ruleArticles: json['ruleArticles'] as String?,
      ruleNextPage: json['ruleNextPage'] as String?,
      ruleTitle: json['ruleTitle'] as String?,
      rulePubDate: json['rulePubDate'] as String?,
      ruleDescription: json['ruleDescription'] as String?,
      ruleImage: json['ruleImage'] as String?,
      ruleLink: json['ruleLink'] as String?,
      ruleContent: json['ruleContent'] as String?,
      contentWhitelist: json['contentWhitelist'] as String?,
      contentBlacklist: json['contentBlacklist'] as String?,
      shouldOverrideUrlLoading: json['shouldOverrideUrlLoading'] as String?,
      style: json['style'] as String?,
      enableJs: json['enableJs'] as bool? ?? true,
      loadWithBaseUrl: json['loadWithBaseUrl'] as bool? ?? true,
      injectJs: json['injectJs'] as String?,
      lastUpdateTime: json['lastUpdateTime'] as int? ?? 0,
      customOrder: json['customOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'sourceIcon': sourceIcon,
      'sourceGroup': sourceGroup,
      'sourceComment': sourceComment,
      'enabled': enabled,
      'variableComment': variableComment,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'sortUrl': sortUrl,
      'singleUrl': singleUrl,
      'articleStyle': articleStyle,
      'ruleArticles': ruleArticles,
      'ruleNextPage': ruleNextPage,
      'ruleTitle': ruleTitle,
      'rulePubDate': rulePubDate,
      'ruleDescription': ruleDescription,
      'ruleImage': ruleImage,
      'ruleLink': ruleLink,
      'ruleContent': ruleContent,
      'contentWhitelist': contentWhitelist,
      'contentBlacklist': contentBlacklist,
      'shouldOverrideUrlLoading': shouldOverrideUrlLoading,
      'style': style,
      'enableJs': enableJs,
      'loadWithBaseUrl': loadWithBaseUrl,
      'injectJs': injectJs,
      'lastUpdateTime': lastUpdateTime,
      'customOrder': customOrder,
    };
  }

  RssSource copyWith({
    String? sourceUrl,
    String? sourceName,
    String? sourceIcon,
    String? sourceGroup,
    String? sourceComment,
    bool? enabled,
    String? variableComment,
    String? jsLib,
    bool? enabledCookieJar,
    String? concurrentRate,
    String? header,
    String? loginUrl,
    String? loginUi,
    String? loginCheckJs,
    String? coverDecodeJs,
    String? sortUrl,
    bool? singleUrl,
    int? articleStyle,
    String? ruleArticles,
    String? ruleNextPage,
    String? ruleTitle,
    String? rulePubDate,
    String? ruleDescription,
    String? ruleImage,
    String? ruleLink,
    String? ruleContent,
    String? contentWhitelist,
    String? contentBlacklist,
    String? shouldOverrideUrlLoading,
    String? style,
    bool? enableJs,
    bool? loadWithBaseUrl,
    String? injectJs,
    int? lastUpdateTime,
    int? customOrder,
  }) {
    return RssSource(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      sourceComment: sourceComment ?? this.sourceComment,
      enabled: enabled ?? this.enabled,
      variableComment: variableComment ?? this.variableComment,
      jsLib: jsLib ?? this.jsLib,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      header: header ?? this.header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      coverDecodeJs: coverDecodeJs ?? this.coverDecodeJs,
      sortUrl: sortUrl ?? this.sortUrl,
      singleUrl: singleUrl ?? this.singleUrl,
      articleStyle: articleStyle ?? this.articleStyle,
      ruleArticles: ruleArticles ?? this.ruleArticles,
      ruleNextPage: ruleNextPage ?? this.ruleNextPage,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      rulePubDate: rulePubDate ?? this.rulePubDate,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      ruleImage: ruleImage ?? this.ruleImage,
      ruleLink: ruleLink ?? this.ruleLink,
      ruleContent: ruleContent ?? this.ruleContent,
      contentWhitelist: contentWhitelist ?? this.contentWhitelist,
      contentBlacklist: contentBlacklist ?? this.contentBlacklist,
      shouldOverrideUrlLoading: shouldOverrideUrlLoading ?? this.shouldOverrideUrlLoading,
      style: style ?? this.style,
      enableJs: enableJs ?? this.enableJs,
      loadWithBaseUrl: loadWithBaseUrl ?? this.loadWithBaseUrl,
      injectJs: injectJs ?? this.injectJs,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      customOrder: customOrder ?? this.customOrder,
    );
  }
}

/// RSS源 DAO（使用 SharedPreferences 持久化存储）
class RssSourceDao {
  static const String _key = 'rss_sources';
  
  final Map<String, RssSource> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data);
        for (final item in list) {
          final source = RssSource.fromJson(item);
          _cache[source.sourceUrl] = source;
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cache.values.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<RssSource>> getAllSources() async {
    await _ensureLoaded();
    return _cache.values.toList();
  }

  Future<List<RssSource>> getEnabledSources() async {
    await _ensureLoaded();
    return _cache.values.where((s) => s.enabled).toList();
  }

  Future<RssSource?> getSource(String url) async {
    await _ensureLoaded();
    return _cache[url];
  }

  Future<void> insertOrUpdateSource(RssSource source) async {
    await _ensureLoaded();
    _cache[source.sourceUrl] = source;
    await _save();
  }

  Future<void> deleteSource(String url) async {
    await _ensureLoaded();
    _cache.remove(url);
    await _save();
  }

  Future<void> toggleEnabled(String url, bool enabled) async {
    await _ensureLoaded();
    final source = _cache[url];
    if (source != null) {
      _cache[url] = source.copyWith(enabled: enabled);
      await _save();
    }
  }
}

/// RSS文章数据类
class RssArticle {
  String origin;
  String sort;
  String title;
  int order;
  String link;
  String? pubDate;
  String? description;
  String? content;
  String? image;
  String group;
  bool read;

  RssArticle({
    required this.origin,
    this.sort = '',
    required this.title,
    this.order = 0,
    required this.link,
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group = '默认分组',
    this.read = false,
  });

  factory RssArticle.fromJson(Map<String, dynamic> json) {
    return RssArticle(
      origin: json['origin'] as String? ?? '',
      sort: json['sort'] as String? ?? '',
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      link: json['link'] as String? ?? '',
      pubDate: json['pubDate'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      image: json['image'] as String?,
      group: json['group'] as String? ?? '默认分组',
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'sort': sort,
      'title': title,
      'order': order,
      'link': link,
      'pubDate': pubDate,
      'description': description,
      'content': content,
      'image': image,
      'group': group,
      'read': read,
    };
  }
}

/// RSS文章 DAO
class RssArticleDao {
  static const String _key = 'rss_articles';
  
  final Map<String, List<RssArticle>> _cache = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(data);
        map.forEach((key, value) {
          if (value is List) {
            _cache[key] = value.map((e) => RssArticle.fromJson(e)).toList();
          }
        });
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    _cache.forEach((key, value) {
      map[key] = value.map((e) => e.toJson()).toList();
    });
    await prefs.setString(_key, jsonEncode(map));
  }

  Future<List<RssArticle>> getArticlesBySource(String origin) async {
    await _ensureLoaded();
    return _cache[origin] ?? [];
  }

  Future<void> saveArticles(String origin, List<RssArticle> articles) async {
    await _ensureLoaded();
    _cache[origin] = articles;
    await _save();
  }

  Future<void> markAsRead(String origin, String link) async {
    await _ensureLoaded();
    final articles = _cache[origin];
    if (articles != null) {
      final article = articles.firstWhere((a) => a.link == link, orElse: () => articles.first);
      article.read = true;
      await _save();
    }
  }
}
