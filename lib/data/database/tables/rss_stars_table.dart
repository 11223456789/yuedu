import 'package:drift/drift.dart';

class RssStars extends Table {
  TextColumn get link => text()(); // PK
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  IntColumn get starTime => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {link};
}
