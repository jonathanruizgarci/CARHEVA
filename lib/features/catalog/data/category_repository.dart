import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/category.dart' as domain;

/// Alta de categorias requiere conexion (la crea el admin, ver
/// docs/plan_de_trabajo.md #3): se escribe primero en Supabase y luego se
/// refleja en la base local para que quede disponible offline de inmediato.
class CategoryRepository {
  CategoryRepository(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseClient _supabase;

  Stream<List<domain.Category>> watchCategories() {
    return _db.select(_db.categories).watch().map(
          (rows) => rows
              .map((r) => domain.Category(id: r.id, name: r.name))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Future<void> createCategory(String name) async {
    final id = const Uuid().v4();

    await _supabase.from('categories').insert({'id': id, 'name': name});

    await _db.into(_db.categories).insertOnConflictUpdate(
          CategoriesCompanion.insert(id: id, name: name),
        );
  }
}
