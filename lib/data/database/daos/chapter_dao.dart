/// 章节 DAO（内存实现）
class ChapterDao {
  final Map<String, List<dynamic>> _chapters = {};
  
  Future<List<dynamic>> getChapters(String bookUrl) async {
    return _chapters[bookUrl] ?? [];
  }
  Future<void> insertChapters(String bookUrl, List<dynamic> chapters) async {
    _chapters[bookUrl] = chapters;
  }
  Future<void> deleteChapters(String bookUrl) async {
    _chapters.remove(bookUrl);
  }
}
