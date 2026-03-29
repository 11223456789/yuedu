import 'daos/book_dao.dart';
import 'daos/book_source_dao.dart';
import 'daos/chapter_dao.dart';
import 'daos/replace_rule_dao.dart';
import 'daos/rss_dao.dart';
import 'daos/bookmark_dao.dart';
import 'daos/read_record_dao.dart';
import 'daos/cache_dao.dart';

/// 简化的 AppDatabase（内存实现，替代 Drift）
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  // DAO 实例
  final BookDao bookDao = BookDao();
  final BookSourceDao bookSourceDao = BookSourceDao();
  final ChapterDao chapterDao = ChapterDao();
  final ReplaceRuleDao replaceRuleDao = ReplaceRuleDao();
  final RssDao rssDao = RssDao();
  final BookmarkDao bookmarkDao = BookmarkDao();
  final ReadRecordDao readRecordDao = ReadRecordDao();
  final CacheDao cacheDao = CacheDao();
}
