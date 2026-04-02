import 'dart:convert';
import '../analyze_rule/analyze_rule.dart';
import '../analyze_rule/analyze_url.dart';
import '../../data/entities/rule/search_rule.dart';
import '../../data/entities/rule/book_info_rule.dart';
import '../../data/entities/rule/toc_rule.dart';
import '../../data/entities/rule/content_rule.dart';
import '../../data/entities/rule/explore_rule.dart';
import '../../data/database/daos/book_source_dao.dart';

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

      final searchRule = source.searchRule;
      final listRule = searchRule.bookList ?? '';
      final elements = await rule.getElements(listRule);

      for (final element in elements) {
        final itemRule = AnalyzeRule();
        itemRule.setContent(element, baseUrl: analyzeUrl.url);

        final name = await itemRule.getString(searchRule.name ?? '');
        final author = await itemRule.getString(searchRule.author ?? '');
        final bookUrl = await itemRule.getString(searchRule.bookUrl ?? '');
        final coverUrl = await itemRule.getString(searchRule.coverUrl ?? '');
        final intro = await itemRule.getString(searchRule.intro ?? '');
        final kind = await itemRule.getString(searchRule.kind ?? '');
        final lastChapter = await itemRule.getString(searchRule.lastChapter ?? '');
        final wordCount = await itemRule.getString(searchRule.wordCount ?? '');

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
    } catch (e) {
      print('搜索失败: $e');
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

      final bookInfoRule = source.bookInfoRule;

      final name = await rule.getString(bookInfoRule.name ?? '') ?? book.name;
      final author = await rule.getString(bookInfoRule.author ?? '') ?? book.author;
      final coverUrl = await rule.getString(bookInfoRule.coverUrl ?? '');
      final intro = await rule.getString(bookInfoRule.intro ?? '');
      final kind = await rule.getString(bookInfoRule.kind ?? '');
      final lastChapter = await rule.getString(bookInfoRule.lastChapter ?? '');
      final tocUrl = await rule.getString(bookInfoRule.tocUrl ?? '');

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
    } catch (e) {
      print('获取详情失败: $e');
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

      final tocRule = source.tocRule;
      final listRule = tocRule.chapterList ?? '';
      final elements = await rule.getElements(listRule);

      int index = 0;
      for (final element in elements) {
        final itemRule = AnalyzeRule();
        itemRule.setContent(element, baseUrl: analyzeUrl.url);

        final title = await itemRule.getString(tocRule.chapterName ?? '');
        final chapterUrl = await itemRule.getString(tocRule.chapterUrl ?? '');

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
    } catch (e) {
      print('获取目录失败: $e');
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

      final contentRule = source.contentRule;
      final contentList = await rule.getStringList(contentRule.content ?? '');

      return contentList.join('\n\n');
    } catch (e) {
      return '加载失败: $e';
    }
  }

  static Map<String, String> _parseHeaders(String? headerStr) {
    if (headerStr == null || headerStr.isEmpty) return {};
    try {
      if (headerStr.trim().startsWith('{')) {
        final decoded = jsonDecode(headerStr);
        if (decoded is Map) {
          final result = <String, String>{};
          decoded.forEach((key, value) {
            result[key.toString()] = value.toString();
          });
          return result;
        }
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
