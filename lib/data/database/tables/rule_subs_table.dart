import 'package:drift/drift.dart';

class RuleSubs extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  IntColumn get type => integer().withDefault(const Constant(0))();
  IntColumn get customOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
