import 'package:drift/drift.dart';

class RssReadRecords extends Table {
  TextColumn get articleId => text()(); // PK
  TextColumn get origin => text().withDefault(const Constant(''))();
  IntColumn get readTime => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {articleId};
}
