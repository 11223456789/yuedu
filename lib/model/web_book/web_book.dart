import '../analyze_rule/analyze_rule.dart';
import '../analyze_rule/analyze_url.dart';

/// 网络书籍操作（搜索、详情、目录、正文）
class WebBook {
  WebBook._();

  /// 搜索书籍
  static Future<List<SearchBook>> search(
    BookSource source,
    String keyword,
  ) async {
    final result = <SearchBook>[];

    try {
      final analyzeUrl = AnalyzeUrl.fromRule(
        source.searchUrl ?? '',
        variables: {'key': keyword},
        sourceHeaders: _parseHeaders(source.header),
      );

      final response = await analyzeUrl.getResponse(
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: analyzeUrl.url);

      final listRule = source.ruleSearchList ?? '';
      final elements = await rule.getElements(listRule);

      for (final element in elements) {
        final itemRule = AnalyzeRule();
        itemRule.setContent(element, baseUrl: analyzeUrl.url);

        final name = await itemRule.getString(source.ruleSearchName ?? '');
        final author = await itemRule.getString(source.ruleSearchAuthor ?? '');
        final bookUrl = await itemRule.getString(source.ruleSearchBookUrl ?? '');
        final coverUrl = await itemRule.getString(source.ruleSearchCoverUrl ?? '');
        final intro = await itemRule.getString(source.ruleSearchIntro ?? '');
        final kind = await itemRule.getString(source.ruleSearchKind ?? '');
        final lastChapter = await itemRule.getString(source.ruleSearchLastChapter ?? '');
        final wordCount = await itemRule.getString(source.ruleSearchWordCount ?? '');

        if (name != null && bookUrl != null) {
          result.add(SearchBook(
            name: name,
            author: author ?? '',
            bookUrl: _resolveUrl(analyzeUrl.url, bookUrl),
            coverUrl: coverUrl != null ? _resolveUrl(analyzeUrl.url, coverUrl) : null,
            intro: intro,
            kind: kind,
            lastChapter: lastChapter,
            wordCount: wordCount,
            origin: source.bookSourceName,
            originUrl: source.bookSourceUrl,
          ));
        }
      }
    } catch (_) {
      // 搜索失败，返回空列表
    }

    return result;
  }

  /// 获取书籍详情
  static Future<Book> getBookInfo(
    BookSource source,
    Book book,
  ) async {
    try {
      final analyzeUrl = AnalyzeUrl.fromRule(
        book.bookUrl,
        baseUrl: book.bookUrl,
        sourceHeaders: _parseHeaders(source.header),
      );

      final response = await analyzeUrl.getResponse(
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: analyzeUrl.url);

      final name = await rule.getString(source.ruleBookName ?? '') ?? book.name;
      final author = await rule.getString(source.ruleBookAuthor ?? '') ?? book.author;
      final coverUrl = await rule.getString(source.ruleCoverUrl ?? '');
      final intro = await rule.getString(source.ruleIntro ?? '');
      final kind = await rule.getString(source.ruleBookKind ?? '');
      final lastChapter = await rule.getString(source.ruleLastChapter ?? '');
      final tocUrl = await rule.getString(source.ruleTocUrl ?? '');

      book.name = name;
      book.author = author;
      if (coverUrl != null) {
        book.coverUrl = _resolveUrl(analyzeUrl.url, coverUrl);
      }
      if (intro != null) {
        book.intro = intro;
      }
      if (kind != null) {
        book.kind = kind;
      }
      if (lastChapter != null) {
        book.latestChapterTitle = lastChapter;
      }
      if (tocUrl != null) {
        book.tocUrl = _resolveUrl(analyzeUrl.url, tocUrl);
      }
    } catch (_) {
      // 获取详情失败，保持原样
    }

    return book;
  }

  /// 获取章节目录
  static Future<List<BookChapter>> getChapterList(
    BookSource source,
    Book book,
  ) async {
    final result = <BookChapter>[];

    try {
      final url = book.tocUrl.isEmpty ? book.bookUrl : book.tocUrl;
      final analyzeUrl = AnalyzeUrl.fromRule(
        url,
        baseUrl: book.bookUrl,
        sourceHeaders: _parseHeaders(source.header),
      );

      final response = await analyzeUrl.getResponse(
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: analyzeUrl.url);

      final listRule = source.ruleChapterList ?? '';
      final elements = await rule.getElements(listRule);

      int index = 0;
      for (final element in elements) {
        final itemRule = AnalyzeRule();
        itemRule.setContent(element, baseUrl: analyzeUrl.url);

        final title = await itemRule.getString(source.ruleChapterName ?? '');
        final chapterUrl = await itemRule.getString(source.ruleContentUrl ?? '');

        if (title != null && chapterUrl != null) {
          result.add(BookChapter(
            url: _resolveUrl(analyzeUrl.url, chapterUrl),
            bookUrl: book.bookUrl,
            title: title,
            index: index++,
            baseUrl: analyzeUrl.url,
          ));
        }
      }
    } catch (_) {
      // 获取目录失败，返回空列表
    }

    return result;
  }

  /// 获取正文内容
  static Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter,
  ) async {
    try {
      final analyzeUrl = AnalyzeUrl.fromRule(
        chapter.url,
        baseUrl: chapter.baseUrl,
        sourceHeaders: _parseHeaders(source.header),
      );

      final response = await analyzeUrl.getResponse(
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: analyzeUrl.url);

      final contentRule = source.ruleContent ?? '';
      final contentList = await rule.getStringList(contentRule);

      return contentList.join('\n\n');
    } catch (e) {
      return '加载失败: $e';
    }
  }

  static Map<String, String> _parseHeaders(String? headerStr) {
    if (headerStr == null || headerStr.isEmpty) return {};
    try {
      // 简单的 Header 解析，支持 JSON 和 key:value 格式
      if (headerStr.trim().startsWith('{')) {
        // TODO: JSON 格式解析
      } else {
        final result = <String, String>{};
        final lines = headerStr.split('\n');
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            result[parts[0].trim()] = parts.sublist(1).join(':').trim();
          }
        }
        return result;
      }
    } catch (_) {}
    return {};
  }

  static String _resolveUrl(String base, String relative) {
    try {
      return Uri.parse(base).resolve(relative).toString();
    } catch (_) {
      return relative;
    }
  }
}

/// 搜索结果书籍
class SearchBook {
  final String name;
  final String author;
  final String bookUrl;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? lastChapter;
  final String? wordCount;
  final String? origin;
  final String? originUrl;

  SearchBook({
    required this.name,
    required this.author,
    required this.bookUrl,
    this.coverUrl,
    this.intro,
    this.kind,
    this.lastChapter,
    this.wordCount,
    this.origin,
    this.originUrl,
  });
}

/// 书籍（简化版）
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
}

/// 书籍章节（简化版）
class BookChapter {
  final String url;
  final String bookUrl;
  final String title;
  final bool isVolume;
  final String baseUrl;
  final int index;
  final bool isVip;
  final bool isPay;
  final String? resourceUrl;
  final String? tag;
  final int? start;
  final int? end;
  final String? variable;

  BookChapter({
    required this.url,
    required this.bookUrl,
    required this.title,
    this.isVolume = false,
    this.baseUrl = '',
    required this.index,
    this.isVip = false,
    this.isPay = false,
    this.resourceUrl,
    this.tag,
    this.start,
    this.end,
    this.variable,
  });
}

/// 书源（简化版）
class BookSource {
  final String bookSourceUrl;
  final String bookSourceName;
  final String? bookSourceGroup;
  final int bookSourceType;
  final String? bookUrlPattern;
  final int customOrder;
  final bool enabled;
  final bool enabledExplore;
  final String? jsLib;
  final bool? enabledCookieJar;
  final String? concurrentRate;
  final String? header;
  final String? loginUrl;
  final String? loginUi;
  final String? loginCheckJs;
  final String? coverDecodeJs;
  final String? bookSourceComment;
  final int lastUpdateTime;
  final int respondTime;
  final int weight;
  final String? exploreUrl;
  final String? searchUrl;
  final String? ruleExplore;
  final String? ruleSearch;
  final String? ruleBookInfo;
  final String? ruleToc;
  final String? ruleContent;

  BookSource({
    required this.bookSourceUrl,
    this.bookSourceName = '',
    this.bookSourceGroup,
    this.bookSourceType = 0,
    this.bookUrlPattern,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.jsLib,
    this.enabledCookieJar,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.bookSourceComment,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.weight = 0,
    this.exploreUrl,
    this.searchUrl,
    this.ruleExplore,
    this.ruleSearch,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
  });

  String? get ruleSearchList => _getRulePart(ruleSearch, 'list');
  String? get ruleSearchName => _getRulePart(ruleSearch, 'name');
  String? get ruleSearchAuthor => _getRulePart(ruleSearch, 'author');
  String? get ruleSearchBookUrl => _getRulePart(ruleSearch, 'bookUrl');
  String? get ruleSearchCoverUrl => _getRulePart(ruleSearch, 'coverUrl');
  String? get ruleSearchIntro => _getRulePart(ruleSearch, 'intro');
  String? get ruleSearchKind => _getRulePart(ruleSearch, 'kind');
  String? get ruleSearchLastChapter => _getRulePart(ruleSearch, 'lastChapter');
  String? get ruleSearchWordCount => _getRulePart(ruleSearch, 'wordCount');

  String? get ruleBookName => _getRulePart(ruleBookInfo, 'name');
  String? get ruleBookAuthor => _getRulePart(ruleBookInfo, 'author');
  String? get ruleCoverUrl => _getRulePart(ruleBookInfo, 'coverUrl');
  String? get ruleIntro => _getRulePart(ruleBookInfo, 'intro');
  String? get ruleBookKind => _getRulePart(ruleBookInfo, 'kind');
  String? get ruleLastChapter => _getRulePart(ruleBookInfo, 'lastChapter');
  String? get ruleTocUrl => _getRulePart(ruleBookInfo, 'tocUrl');

  String? get ruleChapterList => _getRulePart(ruleToc, 'list');
  String? get ruleChapterName => _getRulePart(ruleToc, 'name');
  String? get ruleContentUrl => _getRulePart(ruleToc, 'contentUrl');

  String? _getRulePart(String? ruleJson, String key) {
    if (ruleJson == null || ruleJson.isEmpty) return null;
    // 简单的 JSON 字段提取
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(ruleJson);
    return match?.group(1);
  }
}
