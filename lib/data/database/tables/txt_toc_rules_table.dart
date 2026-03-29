import 'package:drift/drift.dart';

class TxtTocRules extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get rule => text().withDefault(const Constant(''))();
  IntColumn get serialNumber => integer().withDefault(const Constant(0))();
  BoolColumn get enable => boolean().withDefault(const Constant(true))();
}
