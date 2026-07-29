import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/utils/text_normalizer.dart';
import '../../data/category_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/category.dart';
import '../../domain/product.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
  );
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

/// Catalogo local filtrado por texto (nombre), tolerante a acentos y
/// mayusculas. El filtrado es en memoria porque el catalogo del MVP es
/// pequeno (~1000 SKUs, ver docs/plan_de_trabajo.md), asi que no hace falta
/// una extension SQL de normalizacion de acentos.
final filteredProductsProvider = StreamProvider<List<Product>>((ref) {
  final query = ref.watch(catalogSearchQueryProvider);
  final normalizedQuery = normalizeForSearch(query);

  return ref.watch(productRepositoryProvider).watchActiveProducts().map(
        (products) => normalizedQuery.isEmpty
            ? products
            : products
                .where((p) =>
                    normalizeForSearch(p.name).contains(normalizedQuery))
                .toList(),
      );
});
