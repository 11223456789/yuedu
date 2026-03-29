import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/books_table.dart';
import 'tables/book_sources_table.dart';
import 'tables/chapters_table.dart';
import 'tables/book_groups_table.dart';
import 'tables/replace_rules_table.dart';
import 'tables/search_books_table.dart';
import 'tables/search_keywords_table.dart';
import 'tables/rss_sources_table.dart';
import 'tables/bookmarks_table.dart';
import 'tables/rss_articles_table.dart';
import 'tables/rss_stars_table.dart';
import 'tables/rss_read_records_table.dart';
import 'tables/cookies_table.dart';
import 'tables/txt_toc_rules_table.dart';
import 'tables/read_records_table.dart';
import 'tables/http_tts_table.dart';
import 'tables/cache_table.dart';
import 'tables/rule_subs_table.dart';
import 'tables/dict_rules_table.dart';
import 'tables/servers_table.dart';
import 'daos/book_dao.dart';
import 'daos/book_source_dao.dart';
import 'daos/chapter_dao.dart';
import 'daos/replace_rule_dao.dart';
import 'daos/rss_dao.dart';
import 'daos/bookmark_dao.dart';
import 'daos/read_record_dao.dart';
import 'daos/cache_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    BookSources,
    Chapters,
    BookGroups,
    ReplaceRules,
    SearchBooks,
    SearchKeywords,
    RssSources,
    Bookmarks,
    RssArticles,
    RssStars,
    RssReadRecords,
    Cookies,
    TxtTocRules,
    ReadRecords,
    HttpTts,
    Cache,
    RuleSubs,
    DictRules,
    Servers,
  ],
  daos: [
    BookDao,
    BookSourceDao,
    ChapterDao,
    ReplaceRuleDao,
    RssDao,
    BookmarkDao,
    ReadRecordDao,
    CacheDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 未来版本迁移在此添加
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'peiyu_bookhouse');
  }
}
