import 'dart:io';
import '../../data/database/daos/book_dao.dart' show Book, BookChapter;

/// EPUB 书籍解析器
class EpubBook {
  final File file;

  EpubBook({required this.file});

  /// 解析 EPUB 文件获取书籍信息
  Future<Book> parseBookInfo() async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final bookName = fileName.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');

    return Book(
      bookUrl: 'local:${file.path}',
      name: bookName,
      author: '未知',
      intro: '本地 EPUB 书籍',
      type: 1,
    );
  }

  /// 解析 EPUB 文件获取章节目录
  Future<List<BookChapter>> parseChapters(Book book) async {
    final chapters = <BookChapter>[];

    chapters.add(BookChapter(
      url: 'local:${file.path}#0',
      bookUrl: book.bookUrl,
      title: '第一章',
      index: 0,
      baseUrl: '',
    ));

    chapters.add(BookChapter(
      url: 'local:${file.path}#1',
      bookUrl: book.bookUrl,
      title: '第二章',
      index: 1,
      baseUrl: '',
    ));

    return chapters;
  }

  /// 获取指定章节的内容
  Future<String> getChapterContent(BookChapter chapter) async {
    final chapterIndex = _extractChapterIndex(chapter.url);

    return '''这是 EPUB 书籍第 ${(chapterIndex ?? 0) + 1} 章的示例内容。

在实际应用中，这里会显示从 EPUB 文件解析出的章节正文。

EPUB 是一种流行的电子书格式，支持排版和富文本内容。

...''';
  }

  int? _extractChapterIndex(String url) {
    final match = RegExp(r'#(\d+)$').firstMatch(url);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return 0;
  }
}
