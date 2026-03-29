import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/read_records_table.dart';

final readRecordRepositoryProvider = Provider<ReadRecordRepository>((ref) {
  return ReadRecordRepository(ref.watch(appDatabaseProvider));
});

class ReadRecordRepository {
  final AppDatabase _db;
  ReadRecordRepository(this._db);

  Future<List<ReadRecord>> getAllRecords() => _db.readRecordDao.getAllRecords();
  Future<ReadRecord?> getRecord(String bookName) =>
      _db.readRecordDao.getRecord(bookName);

  Future<void> addReadTime(String bookName, String author, int seconds) =>
      _db.readRecordDao.addReadTime(bookName, author, seconds);

  Future<void> deleteRecord(String bookName) =>
      _db.readRecordDao.deleteRecord(bookName);
}
