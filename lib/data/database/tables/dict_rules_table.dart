import 'package:drift/drift.dart';

class DictRules extends Table {
  TextColumn get id => text()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get urlRule => text().withDefault(const Constant(''))();
  TextColumn get jsRule => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get order => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
