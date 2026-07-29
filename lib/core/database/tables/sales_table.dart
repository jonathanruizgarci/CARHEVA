import 'package:drift/drift.dart';

import 'clients_table.dart';

@DataClassName('SaleRow')
class Sales extends Table {
  /// UUID generado en el dispositivo (uuid v4) para poder crear ventas
  /// offline y subirlas despues sin colision de ids con el servidor.
  TextColumn get id => text()();
  TextColumn get clientId => text().nullable().references(Clients, #id)();
  TextColumn get sellerId => text()();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Null mientras la venta no se ha subido a Supabase.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
