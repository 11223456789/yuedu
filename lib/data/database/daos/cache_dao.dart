import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/cache_table.dart';

part 'cache_dao.g.dart';

@DriftAccessor(tables: [Cache])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.db);

  Future<String?> get(String key) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = await (select(cache)
          ..where((c) =>
              c.key.equals(key) &
              (c.deadline.equals(0) | c.deadline.isBiggerThanValue(now))))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> put(String key, String value, {Duration? ttl}) {
    final deadline = ttl != null
        ? DateTime.now().add(ttl).millisecondsSinceEpoch
        : 0;
    return into(cache).insertOnConflictUpdate(
      CacheCompanion(
        key: Value(key),
        value: Value(value),
        deadline: Value(deadline),
      ),
    );
  }

  Future<int> delete(String key) {
    return (delete(cache)..where((c) => c.key.equals(key))).go();
  }

  /// 清理过期缓存
  Future<int> clearExpired() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (delete(cache)
          ..where((c) => c.deadline.isSmallerThanValue(now) & c.deadline.isBiggerThanValue(0)))
        .go();
  }
}
