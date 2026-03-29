import 'package:drift/drift.dart';

class BookSources extends Table {
  TextColumn get bookSourceUrl => text()(); // PK
  TextColumn get bookSourceName => text().withDefault(const Constant(''))();
  TextColumn get bookSourceGroup => text().nullable()();
  IntColumn get bookSourceType => integer().withDefault(const Constant(0))();
  TextColumn get bookUrlPattern => text().nullable()();
  IntColumn get customOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get enabledExplore => boolean().withDefault(const Constant(true))();
  TextColumn get jsLib => text().nullable()();
  BoolColumn get enabledCookieJar => boolean().nullable()();
  TextColumn get concurrentRate => text().nullable()();
  TextColumn get header => text().nullable()();
  TextColumn get loginUrl => text().nullable()();
  TextColumn get loginUi => text().nullable()();
  TextColumn get loginCheckJs => text().nullable()();
  TextColumn get coverDecodeJs => text().nullable()();
  TextColumn get bookSourceComment => text().nullable()();
  IntColumn get lastUpdateTime => integer().withDefault(const Constant(0))();
  IntColumn get respondTime => integer().withDefault(const Constant(180000))();
  IntColumn get weight => integer().withDefault(const Constant(0))();
  TextColumn get exploreUrl => text().nullable()();
  TextColumn get searchUrl => text().nullable()();
  TextColumn get ruleExplore => text().nullable()();
  TextColumn get ruleSearch => text().nullable()();
  TextColumn get ruleBookInfo => text().nullable()();
  TextColumn get ruleToc => text().nullable()();
  TextColumn get ruleContent => text().nullable()();

  @override
  Set<Column> get primaryKey => {bookSourceUrl};
}
