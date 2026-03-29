/// RSS DAO（内存实现）
class RssDao {
  final Map<String, dynamic> _sources = {};
  final List<dynamic> _articles = [];
  
  Future<List<dynamic>> getAllRssSources() async => _sources.values.toList();
  Future<void> insertOrUpdateRssSource(dynamic source) async {
    _sources[source.sourceUrl] = source;
  }
  Future<void> deleteRssSource(String url) async => _sources.remove(url);
  
  Future<List<dynamic>> getRssArticles(String sourceUrl) async {
    return _articles.where((a) => a.sourceUrl == sourceUrl).toList();
  }
  Future<void> insertRssArticles(List<dynamic> articles) async {
    _articles.addAll(articles);
  }
}
