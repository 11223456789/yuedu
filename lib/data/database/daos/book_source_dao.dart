/// 书源 DAO（内存实现）
class BookSourceDao {
  final Map<String, dynamic> _sources = {};
  
  Future<List<dynamic>> getAllSources() async => _sources.values.toList();
  Future<dynamic?> getSource(String url) async => _sources[url];
  Future<void> insertOrUpdateSource(dynamic source) async {
    _sources[source.bookSourceUrl] = source;
  }
  Future<void> deleteSource(String url) async => _sources.remove(url);
}
