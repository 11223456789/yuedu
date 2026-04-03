import 'dart:convert';
import 'package:http/http.dart' as http;
import '../analyze_rule/analyze_rule.dart';
import '../analyze_rule/analyze_url.dart';
import '../../data/entities/rule/search_rule.dart';
import '../../data/entities/rule/book_info_rule.dart';
import '../../data/entities/rule/toc_rule.dart';
import '../../data/entities/rule/content_rule.dart';
import '../../data/database/daos/book_source_dao.dart';

/// HTTP 响应包装
class AnalyzeResponse {
  final String data;
  final String url;
  final int? statusCode;
  final Map<String, String>? headers;

  const AnalyzeResponse({
    required this.data,
    required this.url,
    this.statusCode,
    this.headers,
  });
}

/// URL 分析器（简化版，用于 WebBook）
class _SimpleAnalyzeUrl {
  final http.Client _client = http.Client();
  
  Future<AnalyzeResponse> getResponse(
    String url, {
    String? method,
    String? body,
    Map<String, String>? sourceHeaders,
    String? concurrentRate,
  }) async {
    try {
      // 解析请求头
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      };
      
      if (sourceHeaders != null) {
        headers.addAll(sourceHeaders);
      }

      final requestMethod = (method ?? 'GET').toUpperCase();
      late http.Response response;
      
      if (requestMethod == 'POST') {
        response = await _client.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 30));
      } else {
        response = await _client.get(
          Uri.parse(url),
          headers: headers,
        ).timeout(const Duration(seconds: 30));
      }

      return AnalyzeResponse(
        data: utf8.decode(response.bodyBytes),
        url: response.request?.url.toString() ?? url,
        statusCode: response.statusCode,
        headers: Map<String, String>.from(response.headers),
      );
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// 网络书籍操作（搜索、详情、目录、正文）
class WebBook {
  WebBook._();

  /// 搜索书籍
  static Future<List<SearchBook>> search(
    BookSource source,
    String keyword,
  ) async {
    final result = <SearchBook>[];
    final analyzer = _SimpleAnalyzeUrl();

    try {
      var searchUrlStr = source.searchUrl ?? '';
      if (searchUrlStr.isEmpty) return result;

      // 替换关键词占位符
      searchUrlStr = searchUrlStr
          .replaceAll('{{key}}', Uri.encodeComponent(keyword))
          .replaceAll('{{keyword}}', Uri.encodeComponent(keyword))
          .replaceAll('{searchKey}', Uri.encodeComponent(keyword))
          .replaceAll('{searchWord}', Uri.encodeComponent(keyword))
          .replaceAll('{key}', Uri.encodeComponent(keyword));

      // 判断请求方法
      String? method;
      String? body;
      if (searchUrlStr.startsWith('@post:')) {
        method = 'POST';
        searchUrlStr = searchUrlStr.substring(6);
        final postIdx = searchUrlStr.indexOf(',');
        if (postIdx != -1) {
          body = searchUrlStr.substring(postIdx + 1);
          searchUrlStr = searchUrlStr.substring(0, postIdx);
        }
      } else if (searchUrlStr.startsWith('@post:')) {
        method = 'POST';
        searchUrlStr = searchUrlStr.substring(6);
      }

      final response = await analyzer.getResponse(
        searchUrlStr,
        method: method,
        body: body,
        sourceHeaders: _parseHeaders(source.header),
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: response.url);

      final searchRule = source.searchRule;
      final listRule = searchRule.bookList ?? '';
      
      if (listRule.isEmpty) return result;

      final elements = await rule.getElements(listRule);

      for (final element in elements) {
        final itemRule = AnalyzeRule();
        
        // 如果 element 是字符串（HTML片段），直接设置内容
        if (element is String) {
          itemRule.setContent(element, baseUrl: response.url);
        } else if (element is Map) {
          // 处理 JSON 对象
          itemRule.setContent(jsonEncode(element), baseUrl: response.url);
        } else if (element is List) {
          // 处理 JSON 数组
          itemRule.setContent(jsonEncode(element), baseUrl: response.url);
        } else {
          // 其他类型转换为字符串
          itemRule.setContent(element.toString(), baseUrl: response.url);
        }

        final name = await itemRule.getString(searchRule.name ?? '');
        final author = await itemRule.getString(searchRule.author ?? '');
        final bookUrl = await itemRule.getString(searchRule.bookUrl ?? '', isUrl: true);
        final coverUrl = await itemRule.getString(searchRule.coverUrl ?? '', isUrl: true);
        final intro = await itemRule.getString(searchRule.intro ?? '');
        final kind = await itemRule.getString(searchRule.kind ?? '');
        final lastChapter = await itemRule.getString(searchRule.lastChapter ?? '');
        final wordCount = await itemRule.getString(searchRule.wordCount ?? '');

        if (name != null && name.isNotEmpty && bookUrl != null && bookUrl.isNotEmpty) {
          result.add(SearchBook(
            name: name.trim(),
            author: author?.trim() ?? '',
            bookUrl: bookUrl.trim(),
            coverUrl: coverUrl?.isNotEmpty == true ? coverUrl!.trim() : null,
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
      print('搜索失败 [${source.bookSourceName}]: $e');
    } finally {
      analyzer.dispose();
    }

    return result;
  }

  /// 获取书籍详情
  static Future<Book> getBookInfo(
    BookSource source,
    Book book,
  ) async {
    final analyzer = _SimpleAnalyzeUrl();

    try {
      final response = await analyzer.getResponse(
        book.bookUrl,
        sourceHeaders: _parseHeaders(source.header),
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: response.url);

      final bookInfoRule = source.bookInfoRule;

      final name = await rule.getString(bookInfoRule.name ?? '') ?? book.name;
      final author = await rule.getString(bookInfoRule.author ?? '') ?? book.author;
      final coverUrl = await rule.getString(bookInfoRule.coverUrl ?? '', isUrl: true);
      final intro = await rule.getString(bookInfoRule.intro ?? '');
      final kind = await rule.getString(bookInfoRule.kind ?? '');
      final lastChapter = await rule.getString(bookInfoRule.lastChapter ?? '');
      final tocUrl = await rule.getString(bookInfoRule.tocUrl ?? '', isUrl: true);

      return Book(
        bookUrl: book.bookUrl,
        name: name,
        author: author,
        coverUrl: coverUrl,
        intro: intro,
        kind: kind,
        latestChapterTitle: lastChapter,
        tocUrl: tocUrl,
        durChapterIndex: book.durChapterIndex,
        durChapterPos: book.durChapterPos,
        durChapterTitle: book.durChapterTitle,
        totalChapterNum: book.totalChapterNum,
        origin: book.origin,
        type: book.type,
      );
    } catch (e) {
      print('获取详情失败 [${source.bookSourceName}]: $e');
      return book;
    } finally {
      analyzer.dispose();
    }
  }

  /// 获取章节目录
  static Future<List<BookChapter>> getChapterList(
    BookSource source,
    Book book,
  ) async {
    final result = <BookChapter>[];
    final analyzer = _SimpleAnalyzeUrl();

    try {
      final url = (book.tocUrl?.isNotEmpty == true) ? book.tocUrl! : book.bookUrl;

      final response = await analyzer.getResponse(
        url,
        sourceHeaders: _parseHeaders(source.header),
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: response.url);

      final tocRule = source.tocRule;
      final listRule = tocRule.chapterList ?? '';

      if (listRule.isEmpty) return result;

      final elements = await rule.getElements(listRule);

      int index = 0;
      for (final element in elements) {
        final itemRule = AnalyzeRule();

        if (element is String) {
          itemRule.setContent(element, baseUrl: response.url);
        } else if (element is Map) {
          // 处理 JSON 对象
          itemRule.setContent(jsonEncode(element), baseUrl: response.url);
        } else if (element is List) {
          // 处理 JSON 数组
          itemRule.setContent(jsonEncode(element), baseUrl: response.url);
        } else {
          // 其他类型转换为字符串
          itemRule.setContent(element.toString(), baseUrl: response.url);
        }

        final title = await itemRule.getString(tocRule.chapterName ?? '');
        final chapterUrl = await itemRule.getString(tocRule.chapterUrl ?? '', isUrl: true);

        if (title != null && title.isNotEmpty && chapterUrl != null && chapterUrl.isNotEmpty) {
          result.add(BookChapter(
            url: chapterUrl.trim(),
            bookUrl: book.bookUrl,
            title: title.trim(),
            index: index++,
            baseUrl: response.url,
          ));
        }
      }
    } catch (e) {
      print('获取目录失败 [${source.bookSourceName}]: $e');
    } finally {
      analyzer.dispose();
    }

    return result;
  }

  /// 获取正文内容
  static Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter,
  ) async {
    final analyzer = _SimpleAnalyzeUrl();

    try {
      final contentUrl = chapter.url.isNotEmpty ? chapter.url : book.bookUrl;

      final response = await analyzer.getResponse(
        contentUrl,
        sourceHeaders: _parseHeaders(source.header),
        concurrentRate: source.concurrentRate,
      );

      final rule = AnalyzeRule();
      rule.setContent(response.data, baseUrl: response.url);

      final contentRule = source.contentRule;
      
      // 尝试获取正文
      var contentList = <String>[];

      // 优先使用 content 规则获取列表
      if (contentRule.content?.isNotEmpty == true) {
        contentList = await rule.getStringList(contentRule.content!);
      }

      // 如果列表为空，尝试使用 nextContentUrl 获取更多内容
      if (contentList.isEmpty && contentRule.nextContentUrl?.isNotEmpty == true) {
        // 有些书源正文分页
        final nextUrl = await rule.getString(contentRule.nextContentUrl!, isUrl: true);
        if (nextUrl?.isNotEmpty == true) {
          try {
            final nextResponse = await analyzer.getResponse(
              nextUrl!,
              sourceHeaders: _parseHeaders(source.header),
              concurrentRate: source.concurrentRate,
            );
            
            final nextRule = AnalyzeRule();
            nextRule.setContent(nextResponse.data, baseUrl: nextResponse.url);
            contentList = await nextRule.getStringList(contentRule.content!);
          } catch (_) {}
        }
      }

      // 如果还是空，尝试用 getString 获取单个文本块
      if (contentList.isEmpty && contentRule.content?.isNotEmpty == true) {
        final singleContent = await rule.getString(contentRule.content!);
        if (singleContent != null && singleContent.isNotEmpty) {
          contentList = [singleContent];
        }
      }

      // 清理内容
      final cleanedContent = contentList
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.replaceAll(RegExp(r'\s{2,}'), '\n').trim())
          .where((s) => s.length > 2)
          .toList();

      if (cleanedContent.isEmpty) {
        throw Exception('未匹配到正文内容');
      }

      return cleanedContent.join('\n\n');
    } catch (e) {
      print('获取正文失败 [${source.bookSourceName}]: $e');
      rethrow;
    } finally {
      analyzer.dispose();
    }
  }

  /// 解析请求头
  static Map<String, String> _parseHeaders(String? headerStr) {
    if (headerStr == null || headerStr.isEmpty) return {};
    
    try {
      final trimmed = headerStr.trim();
      
      // JSON 格式
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final result = <String, String>{};
          decoded.forEach((key, value) {
            result[key.toString()] = value.toString();
          });
          return result;
        }
        if (decoded is List) {
          final result = <String, String>{};
          for (final item in decoded) {
            if (item is Map) {
              item.forEach((key, value) {
                result[key.toString()] = value.toString();
              });
            }
          }
          return result;
        }
      }
      
      // 文本格式：每行 "Key: Value"
      final result = <String, String>{};
      final lines = trimmed.split(RegExp(r'[\n\r]+'));
      for (final line in lines) {
        final colonIdx = line.indexOf(':');
        if (colonIdx > 0) {
          final key = line.substring(0, colonIdx).trim();
          final value = line.substring(colonIdx + 1).trim();
          if (key.isNotEmpty) {
            result[key] = value;
          }
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// 解析相对 URL 为绝对 URL
  static String resolveUrl(String base, String relative) {
    if (relative.isEmpty) return base;
    if (relative.startsWith('http://') || relative.startsWith('https://')) {
      return relative;
    }
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

  SearchBook copyWith({
    String? name,
    String? author,
    String? bookUrl,
    String? coverUrl,
    String? intro,
    String? kind,
    String? lastChapter,
    String? wordCount,
    String? origin,
    String? originUrl,
  }) {
    return SearchBook(
      name: name ?? this.name,
      author: author ?? this.author,
      bookUrl: bookUrl ?? this.bookUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      kind: kind ?? this.kind,
      lastChapter: lastChapter ?? this.lastChapter,
      wordCount: wordCount ?? this.wordCount,
      origin: origin ?? this.origin,
      originUrl: originUrl ?? this.originUrl,
    );
  }

  @override
  String toString() => 'SearchBook($name by $author)';
}

/// 书籍章节
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

  @override
  String toString() => 'BookChapter[$index] $title';
}

/// 书籍数据模型
class Book {
  String bookUrl;
  String name;
  String author;
  String? coverUrl;
  String? intro;
  String? kind;
  String? latestChapterTitle;
  String? tocUrl;
  int durChapterIndex;
  int durChapterPos;
  String? durChapterTitle;
  int totalChapterNum;
  String? origin;
  int type;

  Book({
    required this.bookUrl,
    required this.name,
    required this.author,
    this.coverUrl,
    this.intro,
    this.kind,
    this.latestChapterTitle,
    this.tocUrl,
    this.durChapterIndex = 0,
    this.durChapterPos = 0,
    this.durChapterTitle,
    this.totalChapterNum = 0,
    this.origin,
    this.type = 1,
  });

  Book copyWith({
    String? bookUrl,
    String? name,
    String? author,
    String? coverUrl,
    String? intro,
    String? kind,
    String? latestChapterTitle,
    String? tocUrl,
    int? durChapterIndex,
    int? durChapterPos,
    String? durChapterTitle,
    int? totalChapterNum,
    String? origin,
    int? type,
  }) {
    return Book(
      bookUrl: bookUrl ?? this.bookUrl,
      name: name ?? this.name,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      kind: kind ?? this.kind,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      tocUrl: tocUrl ?? this.tocUrl,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      durChapterPos: durChapterPos ?? this.durChapterPos,
      durChapterTitle: durChapterTitle ?? this.durChapterTitle,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      origin: origin ?? this.origin,
      type: type ?? this.type,
    );
  }
}
