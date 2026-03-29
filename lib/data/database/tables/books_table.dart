import 'package:drift/drift.dart';

class Books extends Table {
  TextColumn get bookUrl => text()(); // PK
  TextColumn get tocUrl => text().withDefault(const Constant(''))();
  TextColumn get origin => text().withDefault(const Constant('local'))();
  TextColumn get originName => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get kind => text().nullable()();
  TextColumn get customTag => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get customCoverUrl => text().nullable()();
  TextColumn get intro => text().nullable()();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get bookGroup => integer().withDefault(const Constant(0))();
  TextColumn get latestChapterTitle => text().nullable()();
  IntColumn get latestChapterTime => integer().withDefault(const Constant(0))();
  IntColumn get totalChapterNum => integer().withDefault(const Constant(0))();
  TextColumn get durChapterTitle => text().nullable()();
  IntColumn get durChapterIndex => integer().withDefault(const Constant(0))();
  IntColumn get durChapterPos => integer().withDefault(const Constant(0))();
  IntColumn get durChapterTime => integer().withDefault(const Constant(0))();
  BoolColumn get canUpdate => boolean().withDefault(const Constant(true))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get variable => text().nullable()();
  TextColumn get readConfig => text().nullable()();

  @override
  Set<Column> get primaryKey => {bookUrl};
}
