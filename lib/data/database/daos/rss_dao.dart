import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rss_sources_table.dart';
import '../tables/rss_articles_table.dart';
import '../tables/rss_stars_table.dart';
import '../tables/rss_read_records_table.dart';

part 'rss_dao.g.dart';

@DriftAccessor(tables: [RssSources, RssArticles, RssStars, RssReadRecords])
class RssDao extends DatabaseAccessor<AppDatabase> with _$RssDaoMixin {
  RssDao(super.db);

  // ── RSS 源 ──────────────────────────────────────────────
  Future<List<RssSource>> getAllRssSources() => select(rssSources).get();
  Stream<List<RssSource>> watchAllRssSources() => select(rssSources).watch();

  Future<void> insertOrUpdateRssSource(RssSourcesCompanion source) =>
      into(rssSources).insertOnConflictUpdate(source);

  Future<int> deleteRssSource(String url) {
    return (delete(rssSources)..where((s) => s.sourceUrl.equals(url))).go();
  }

  // ── RSS 文章 ─────────────────────────────────────────────
  Future<List<RssArticle>> getArticlesByOrigin(String origin) {
    return (select(rssArticles)..where((a) => a.origin.equals(origin))).get();
  }

  Future<void> insertOrUpdateArticle(RssArticlesCompanion article) =>
      into(rssArticles).insertOnConflictUpdate(article);

  Future<int> deleteArticlesByOrigin(String origin) {
    return (delete(rssArticles)..where((a) => a.origin.equals(origin))).go();
  }

  // ── RSS 收藏 ─────────────────────────────────────────────
  Future<List<RssStar>> getAllStars() => select(rssStars).get();

  Future<void> insertOrUpdateStar(RssStarsCompanion star) =>
      into(rssStars).insertOnConflictUpdate(star);

  Future<int> deleteStar(String link) {
    return (delete(rssStars)..where((s) => s.link.equals(link))).go();
  }

  // ── RSS 阅读记录 ──────────────────────────────────────────
  Future<bool> isRead(String articleId) async {
    final record = await (select(rssReadRecords)
          ..where((r) => r.articleId.equals(articleId)))
        .getSingleOrNull();
    return record != null;
  }

  Future<void> markAsRead(String articleId, String origin) =>
      into(rssReadRecords).insertOnConflictUpdate(
        RssReadRecordsCompanion(
          articleId: Value(articleId),
          origin: Value(origin),
          readTime: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
}
