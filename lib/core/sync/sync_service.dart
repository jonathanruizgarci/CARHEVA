import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

/// Sincroniza la base de datos local (fuente de verdad inmediata) con
/// Supabase (respaldo centralizado). Ver docs/ARCHITECTURE.md ("Offline-first").
///
/// Estrategia del MVP:
/// - Subida: procesa `sync_queue` (outbox) en orden de creacion; clientes y
///   ventas (con su detalle) creados offline.
/// - Bajada: reemplaza categorias y productos locales con el estado actual
///   del servidor (catalogo completo, ~1000 SKUs segun el plan de trabajo -
///   no amerita sincronizacion incremental por ahora).
/// - Conflictos: "ultima escritura gana" vía `updated_at`; el stock final
///   siempre lo calcula el servidor (trigger `on_sale_item_created`).
class SyncService {
  SyncService(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseClient _supabase;

  Future<void> syncNow() async {
    await _uploadPendingChanges();
    await _downloadCatalog();
  }

  Future<void> _uploadPendingChanges() async {
    final pending = await (_db.select(_db.syncQueue)
          ..where((t) => t.syncedAt.isNull()))
        .get();

    for (final entry in pending) {
      switch (entry.entityTable) {
        case 'clients':
          await _uploadClient(entry.entityId);
          break;
        case 'sales':
          await _uploadSale(entry.entityId);
          break;
      }

      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(entry.id)))
          .write(SyncQueueCompanion(syncedAt: Value(DateTime.now())));
    }
  }

  Future<void> _uploadClient(String clientId) async {
    final client = await (_db.select(_db.clients)
          ..where((t) => t.id.equals(clientId)))
        .getSingleOrNull();
    if (client == null) return;

    await _supabase.from('clients').upsert({
      'id': client.id,
      'name': client.name,
      'contact': client.contact,
      'notes': client.notes,
      'created_by': client.createdBy,
    });
  }

  Future<void> _uploadSale(String saleId) async {
    final sale = await (_db.select(_db.sales)
          ..where((t) => t.id.equals(saleId)))
        .getSingleOrNull();
    if (sale == null) return;

    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();

    await _supabase.from('sales').upsert({
      'id': sale.id,
      'client_id': sale.clientId,
      'seller_id': sale.sellerId,
      'total': sale.total,
    });

    await _supabase.from('sale_items').upsert([
      for (final item in items)
        {
          'id': item.id,
          'sale_id': item.saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        },
    ]);

    await (_db.update(_db.sales)..where((t) => t.id.equals(saleId)))
        .write(SalesCompanion(syncedAt: Value(DateTime.now())));
  }

  Future<void> _downloadCatalog() async {
    final categories = await _supabase.from('categories').select();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.categories,
        [
          for (final row in categories)
            CategoriesCompanion.insert(
              id: row['id'] as String,
              name: row['name'] as String,
            ),
        ],
      );
    });

    final products = await _supabase.from('products').select();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.products,
        [
          for (final row in products)
            ProductsCompanion.insert(
              id: row['id'] as String,
              name: row['name'] as String,
              categoryId: Value(row['category_id'] as String?),
              type: row['type'] as String,
              brand: Value(row['brand'] as String?),
              price: (row['price'] as num).toDouble(),
              stock: Value(row['stock'] as int),
              unitsPerBox: Value(row['units_per_box'] as int?),
              status: Value(row['status'] as String),
              imageUrl: Value(row['image_url'] as String?),
            ),
        ],
      );
    });
  }
}
