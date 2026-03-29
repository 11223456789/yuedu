import 'package:drift/drift.dart';

class BookGroups extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get groupName => text().withDefault(const Constant(''))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  BoolColumn get show => boolean().withDefault(const Constant(true))();
}
