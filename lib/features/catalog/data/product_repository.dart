import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/product.dart' as domain;

/// Alta/edicion de productos requiere conexion (la crea/edita el admin, ver
/// docs/plan_de_trabajo.md #3): se escribe primero en Supabase y luego se
/// refleja en la base local. La lectura (catalogo) siempre viene de la base
/// local, para que el vendedor pueda navegarlo sin internet.
class ProductRepository {
  ProductRepository(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseClient _supabase;

  Stream<List<domain.Product>> watchActiveProducts() {
    final query = _db.select(_db.products)
      ..where((t) => t.status.equals('activo'))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  Future<void> createProduct({
    required String name,
    required domain.ProductType type,
    required double price,
    required int stock,
    String? categoryId,
    String? brand,
    int? unitsPerBox,
    String? imageUrl,
  }) async {
    final id = const Uuid().v4();
    final typeStr = _typeToString(type);

    await _supabase.from('products').insert({
      'id': id,
      'name': name,
      'category_id': categoryId,
      'type': typeStr,
      'brand': brand,
      'price': price,
      'stock': stock,
      'units_per_box': unitsPerBox,
      'image_url': imageUrl,
    });

    await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion.insert(
            id: id,
            name: name,
            type: typeStr,
            price: price,
            categoryId: Value(categoryId),
            brand: Value(brand),
            stock: Value(stock),
            unitsPerBox: Value(unitsPerBox),
            imageUrl: Value(imageUrl),
          ),
        );
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required domain.ProductType type,
    required double price,
    required int stock,
    String? categoryId,
    String? brand,
    int? unitsPerBox,
    String? imageUrl,
  }) async {
    final typeStr = _typeToString(type);

    await _supabase.from('products').update({
      'name': name,
      'category_id': categoryId,
      'type': typeStr,
      'brand': brand,
      'price': price,
      'stock': stock,
      'units_per_box': unitsPerBox,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        name: Value(name),
        categoryId: Value(categoryId),
        type: Value(typeStr),
        brand: Value(brand),
        price: Value(price),
        stock: Value(stock),
        unitsPerBox: Value(unitsPerBox),
        imageUrl: Value(imageUrl),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setStatus(String id, domain.ProductStatus status) async {
    final statusStr = _statusToString(status);

    await _supabase
        .from('products')
        .update({'status': statusStr}).eq('id', id);

    await (_db.update(_db.products)..where((t) => t.id.equals(id)))
        .write(ProductsCompanion(status: Value(statusStr)));
  }

  domain.Product _toEntity(ProductRow r) => domain.Product(
        id: r.id,
        name: r.name,
        categoryId: r.categoryId,
        type: r.type == 'formula'
            ? domain.ProductType.formula
            : domain.ProductType.generico,
        brand: r.brand,
        price: r.price,
        stock: r.stock,
        unitsPerBox: r.unitsPerBox,
        status: r.status == 'descontinuado'
            ? domain.ProductStatus.descontinuado
            : domain.ProductStatus.activo,
        imageUrl: r.imageUrl,
      );

  String _typeToString(domain.ProductType type) =>
      type == domain.ProductType.formula ? 'formula' : 'generico';

  String _statusToString(domain.ProductStatus status) =>
      status == domain.ProductStatus.descontinuado ? 'descontinuado' : 'activo';
}
