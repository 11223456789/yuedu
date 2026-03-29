import 'package:drift/drift.dart';

class ReadRecords extends Table {
  TextColumn get bookName => text()(); // PK
  TextColumn get bookAuthor => text().withDefault(const Constant(''))();
  IntColumn get readTime => integer().withDefault(const Constant(0))();
  IntColumn get lastReadTime => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {bookName};
}
