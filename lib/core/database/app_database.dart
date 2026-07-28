import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'tables/categories_table.dart';
import 'tables/clients_table.dart';
import 'tables/products_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sales_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Products, Clients, Sales, SaleItems, SyncQueue],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  @override
  int get schemaVersion => 1;
}
