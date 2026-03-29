import 'package:drift/drift.dart';

class Cookies extends Table {
  TextColumn get id => text()(); // PK
  TextColumn get cookie => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
