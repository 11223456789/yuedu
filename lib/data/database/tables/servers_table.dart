import 'package:drift/drift.dart';

class Servers extends Table {
  TextColumn get id => text()(); // PK
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  IntColumn get serverType => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
