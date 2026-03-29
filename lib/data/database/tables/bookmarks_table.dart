import 'package:drift/drift.dart';

class Bookmarks extends Table {
  IntColumn get time => integer()(); // PK
  TextColumn get bookUrl => text().withDefault(const Constant(''))();
  TextColumn get bookName => text().withDefault(const Constant(''))();
  IntColumn get chapterIndex => integer().withDefault(const Constant(0))();
  IntColumn get chapterPos => integer().withDefault(const Constant(0))();
  TextColumn get chapterName => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get color => integer().nullable()();

  @override
  Set<Column> get primaryKey => {time};
}
