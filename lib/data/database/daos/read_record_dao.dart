/// 简化的阅读记录 DAO（内存实现）
class ReadRecordDao {
  final Map<String, ReadRecord> _records = {};

  Future<List<ReadRecord>> getAllRecords() async {
    final list = _records.values.toList();
    list.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
    return list;
  }

  Future<ReadRecord?> getRecord(String bookName) async {
    return _records[bookName];
  }

  Future<void> addReadTime(String bookName, String author, int seconds) async {
    final existing = _records[bookName];
    if (existing != null) {
      existing.readTime += seconds;
      existing.lastReadTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      _records[bookName] = ReadRecord(
        bookName: bookName,
        bookAuthor: author,
        readTime: seconds,
        lastReadTime: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<int> deleteRecord(String bookName) async {
    final existed = _records.containsKey(bookName);
    _records.remove(bookName);
    return existed ? 1 : 0;
  }
}

/// 阅读记录数据类
class ReadRecord {
  String bookName;
  String bookAuthor;
  int readTime;
  int lastReadTime;

  ReadRecord({
    required this.bookName,
    required this.bookAuthor,
    required this.readTime,
    required this.lastReadTime,
  });
}
