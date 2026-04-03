import 'dart:convert';
import '../analyze_rule/analyze_rule.dart';
import '../../data/database/daos/book_source_dao.dart' show BookSource;
import 'web_book.dart' show SearchBook;

/// 书籍列表解析（复刻 legado 的 BookList）
class BookList {
  /// 解析书籍列表
  static Future<List<SearchBook>> analyzeBookList({
    required BookSource bookSource,
    required String baseUrl,
    required String body,
    required bool isSearch,
  }) async {
    final bookList = <SearchBook>[];
    
    try {
      final analyzeRule = AnalyzeRule();
      analyzeRule.setContent(body, baseUrl: baseUrl);
      
      // 获取书籍列表规则
      final bookListRule = isSearch 
          ? bookSource.searchRule 
          : (bookSource.exploreRule.bookList?.isEmpty == true 
              ? bookSource.searchRule 
              : bookSource.exploreRule);
      
      final ruleList = bookListRule.bookList ?? '';
      if (ruleList.isEmpty) {
        print('书籍列表规则为空');
        return bookList;
      }
      
      // 获取书籍列表元素
      final collections = await analyzeRule.getElements(ruleList);
      
      for (var i = 0; i < collections.length; i++) {
        final element = collections[i];
        
        try {
          final itemRule = AnalyzeRule();
          
          // 设置内容
          if (element is String) {
            itemRule.setContent(element, baseUrl: baseUrl);
          } else if (element is Map) {
            itemRule.setContent(jsonEncode(element), baseUrl: baseUrl);
          } else {
            itemRule.setContent(element.toString(), baseUrl: baseUrl);
          }
          
          // 解析书籍信息
          final name = await itemRule.getString(bookListRule.name ?? '');
          final author = await itemRule.getString(bookListRule.author ?? '');
          final bookUrl = await itemRule.getString(bookListRule.bookUrl ?? '', isUrl: true);
          final coverUrl = await itemRule.getString(bookListRule.coverUrl ?? '', isUrl: true);
          final intro = await itemRule.getString(bookListRule.intro ?? '');
          final kind = await itemRule.getString(bookListRule.kind ?? '');
          final lastChapter = await itemRule.getString(bookListRule.lastChapter ?? '');
          final wordCount = await itemRule.getString(bookListRule.wordCount ?? '');
          
          if (name != null && name.isNotEmpty && bookUrl != null && bookUrl.isNotEmpty) {
            bookList.add(SearchBook(
              name: name.trim(),
              author: author?.trim() ?? '',
              bookUrl: bookUrl.trim(),
              coverUrl: coverUrl?.isNotEmpty == true ? coverUrl.trim() : null,
              intro: intro,
              kind: kind,
              lastChapter: lastChapter,
              wordCount: wordCount,
              origin: bookSource.bookSourceName,
              originUrl: bookSource.bookSourceUrl,
            ));
          }
        } catch (e) {
          print('解析第 $i 本书失败: $e');
        }
      }
    } catch (e) {
      print('解析书籍列表失败: $e');
    }
    
    return bookList;
  }
}
