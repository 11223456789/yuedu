import 'package:drift/drift.dart';

class ReplaceRules extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get pattern => text().withDefault(const Constant(''))();
  TextColumn get replacement => text().withDefault(const Constant(''))();
  BoolColumn get isRegex => boolean().withDefault(const Constant(false))();
  TextColumn get scope => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get group => text().nullable()();
}
