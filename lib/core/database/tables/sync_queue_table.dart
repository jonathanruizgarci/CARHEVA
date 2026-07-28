import 'package:drift/drift.dart';

/// Outbox de cambios locales pendientes de subir a Supabase.
/// entityTable: 'clients' | 'sales'. operation: por ahora solo 'insert'
/// (el MVP no contempla editar/borrar clientes o ventas offline).
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}
