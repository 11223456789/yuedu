import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/read_records_table.dart';

part 'read_record_dao.g.dart';

@DriftAccessor(tables: [ReadRecords])
class ReadRecordDao extends DatabaseAccessor<AppDatabase>
    with _$ReadRecordDaoMixin {
  ReadRecordDao(super.db);

  Future<List<ReadRecord>> getAllRecords() {
    return (select(readRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.lastReadTime)]))
        .get();
  }

  Future<ReadRecord?> getRecord(String bookName) {
    return (select(readRecords)
          ..where((r) => r.bookName.equals(bookName)))
        .getSingleOrNull();
  }

  Future<void> addReadTime(String bookName, String author, int seconds) async {
    final existing = await getRecord(bookName);
    if (existing != null) {
      await (update(readRecords)..where((r) => r.bookName.equals(bookName)))
          .write(ReadRecordsCompanion(
        readTime: Value(existing.readTime + seconds),
        lastReadTime: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    } else {
      await into(readRecords).insert(ReadRecordsCompanion(
        bookName: Value(bookName),
        bookAuthor: Value(author),
        readTime: Value(seconds),
        lastReadTime: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }
  }

  Future<int> deleteRecord(String bookName) {
    return (delete(readRecords)..where((r) => r.bookName.equals(bookName))).go();
  }
}
