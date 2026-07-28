import 'package:drift/drift.dart';

import 'categories_table.dart';

/// tipo: 'generico' | 'formula'. estado: 'activo' | 'descontinuado'.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get type => text()();
  TextColumn get brand => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get unitsPerBox => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('activo'))();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
