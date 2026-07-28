import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Instancia unica de la base de datos local (SQLite/Drift) para toda la app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
