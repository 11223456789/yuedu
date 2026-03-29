import 'dart:io';
import '../../data/database/tables/books_table.dart';
import '../../data/database/tables/chapters_table.dart';

/// TXT 书籍解析器
class TxtBook {
  final File file;
  final String? tocRule;

  TxtBook({
    required this.file,
    this.tocRule,
  });

  /// 解析 TXT 文件获取书籍信息
  Future<Book> parseBookInfo() async {
    final content = await file.readAsString();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final bookName = fileName.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');

    return Book(
      bookUrl: 'local:${file.path}',
      name: bookName,
      author: '未知',
      intro: '本地 TXT 书籍',
      type: 0,
    );
  }

  /// 解析 TXT 文件获取章节目录
  Future<List<BookChapter>> parseChapters(Book book) async {
    final content = await file.readAsString();
    final chapters = <BookChapter>[];

    final chapterPatterns = [
      RegExp(r'第[0-9一二三四五六七八九十百千万]+章'),
      RegExp(r'第[0-9]+章'),
      RegExp(r'^[0-9]+\.'),
      RegExp(r'^\d+、'),
    ];

    int index = 0;
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      bool isChapter = false;
      for (final pattern in chapterPatterns) {
        if (pattern.hasMatch(line)) {
          isChapter = true;
          break;
        }
      }

      if (isChapter) {
        chapters.add(BookChapter(
          url: 'local:${file.path}#$i',
          bookUrl: book.bookUrl,
          title: line,
          index: index++,
          baseUrl: '',
        ));
      }
    }

    if (chapters.isEmpty) {
      chapters.add(BookChapter(
        url: 'local:${file.path}',
        bookUrl: book.bookUrl,
        title: '正文',
        index: 0,
        baseUrl: '',
      ));
    }

    return chapters;
  }

  /// 获取指定章节的内容
  Future<String> getChapterContent(BookChapter chapter) async {
    final content = await file.readAsString();
    final lines = content.split('\n');

    final chapterIndex = _extractChapterIndex(chapter.url);
    if (chapterIndex == null) {
      return content;
    }

    final StringBuffer result = StringBuffer();
    bool inChapter = false;
    int currentChapterIndex = 0;

    for (final line in lines) {
      if (_isChapterLine(line)) {
        if (currentChapterIndex == chapterIndex) {
          inChapter = true;
        } else if (inChapter) {
          break;
        }
        currentChapterIndex++;
      }

      if (inChapter) {
        result.writeln(line);
      }
    }

    return result.toString();
  }

  int? _extractChapterIndex(String url) {
    final match = RegExp(r'#(\d+)$').firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  bool _isChapterLine(String line) {
    final chapterPatterns = [
      RegExp(r'第[0-9一二三四五六七八九十百千万]+章'),
      RegExp(r'第[0-9]+章'),
      RegExp(r'^[0-9]+\.'),
      RegExp(r'^\d+、'),
    ];

    for (final pattern in chapterPatterns) {
      if (pattern.hasMatch(line.trim())) {
        return true;
      }
    }
    return false;
  }
}
