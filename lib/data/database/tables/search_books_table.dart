import 'package:drift/drift.dart';

class SearchBooks extends Table {
  TextColumn get bookUrl => text()(); // PK
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get originName => text().withDefault(const Constant(''))();
  IntColumn get type => integer().withDefault(const Constant(0))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get kind => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get intro => text().nullable()();
  TextColumn get wordCount => text().nullable()();
  TextColumn get latestChapterTitle => text().nullable()();
  TextColumn get tocUrl => text().withDefault(const Constant(''))();
  IntColumn get time => integer().withDefault(const Constant(0))();
  TextColumn get variable => text().nullable()();
  IntColumn get originOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {bookUrl};
}
