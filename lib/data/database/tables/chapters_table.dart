import 'package:drift/drift.dart';

import 'books_table.dart';

class Chapters extends Table {
  TextColumn get url => text()(); // PK part1
  TextColumn get bookUrl => text().references(Books, #bookUrl,
      onDelete: KeyAction.cascade)(); // PK part2
  TextColumn get title => text().withDefault(const Constant(''))();
  BoolColumn get isVolume => boolean().withDefault(const Constant(false))();
  TextColumn get baseUrl => text().withDefault(const Constant(''))();
  IntColumn get chapterIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isVip => boolean().withDefault(const Constant(false))();
  BoolColumn get isPay => boolean().withDefault(const Constant(false))();
  TextColumn get resourceUrl => text().nullable()();
  TextColumn get tag => text().nullable()();
  IntColumn get start => integer().nullable()();
  IntColumn get end => integer().nullable()();
  TextColumn get variable => text().nullable()();

  @override
  Set<Column> get primaryKey => {url, bookUrl};
}
