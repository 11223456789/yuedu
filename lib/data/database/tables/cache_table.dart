import 'package:drift/drift.dart';

class Cache extends Table {
  TextColumn get key => text()(); // PK
  TextColumn get value => text().nullable()();
  IntColumn get deadline => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}
