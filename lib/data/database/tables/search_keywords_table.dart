import 'package:drift/drift.dart';

class SearchKeywords extends Table {
  IntColumn get id => integer().autoIncrement()(); // PK
  TextColumn get word => text().withDefault(const Constant(''))();
  IntColumn get usage => integer().withDefault(const Constant(0))();
  IntColumn get lastUseTime => integer().withDefault(const Constant(0))();
}
