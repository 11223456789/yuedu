import 'package:drift/drift.dart';

class RssArticles extends Table {
  TextColumn get link => text()(); // PK
  TextColumn get origin => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().nullable()();
  TextColumn get img => text().nullable()();
  TextColumn get pubDate => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get categories => text().nullable()();
  TextColumn get guid => text().nullable()();

  @override
  Set<Column> get primaryKey => {link};
}
