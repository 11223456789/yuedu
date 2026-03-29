import 'package:drift/drift.dart';

class RssSources extends Table {
  TextColumn get sourceUrl => text()(); // PK
  TextColumn get sourceName => text().withDefault(const Constant(''))();
  TextColumn get sourceIcon => text().nullable()();
  TextColumn get sourceGroup => text().nullable()();
  TextColumn get sourceComment => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get enabledCookieJar => boolean().nullable()();
  TextColumn get concurrentRate => text().nullable()();
  TextColumn get header => text().nullable()();
  TextColumn get loginUrl => text().nullable()();
  TextColumn get loginUi => text().nullable()();
  TextColumn get loginCheckJs => text().nullable()();
  IntColumn get customOrder => integer().withDefault(const Constant(0))();
  IntColumn get lastUpdateTime => integer().withDefault(const Constant(0))();
  IntColumn get respondTime => integer().withDefault(const Constant(180000))();
  IntColumn get weight => integer().withDefault(const Constant(0))();
  TextColumn get ruleArticles => text().nullable()();
  TextColumn get ruleNextPage => text().nullable()();
  TextColumn get ruleTitle => text().nullable()();
  TextColumn get ruleGuid => text().nullable()();
  TextColumn get rulePubDate => text().nullable()();
  TextColumn get ruleCategories => text().nullable()();
  TextColumn get ruleDescription => text().nullable()();
  TextColumn get ruleImage => text().nullable()();
  TextColumn get ruleContent => text().nullable()();
  TextColumn get style => text().nullable()();
  TextColumn get ruleLink => text().nullable()();
  TextColumn get injectJs => text().nullable()();
  BoolColumn get loadWithBaseUrl =>
      boolean().withDefault(const Constant(false))();
  TextColumn get checkKeyWord => text().nullable()();

  @override
  Set<Column> get primaryKey => {sourceUrl};
}
