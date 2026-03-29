import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// 全局数据库单例 Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
