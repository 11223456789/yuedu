import 'package:drift/drift.dart';

class HttpTts extends Table {
  TextColumn get id => text()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get contentType =>
      text().withDefault(const Constant('audio/mpeg'))();
  TextColumn get header => text().nullable()();
  TextColumn get loginUrl => text().nullable()();
  TextColumn get loginUi => text().nullable()();
  TextColumn get loginCheckJs => text().nullable()();
  TextColumn get concurrentRate => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get order => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
