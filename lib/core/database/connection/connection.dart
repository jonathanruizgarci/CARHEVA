import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Abre la base de datos SQLite local en el directorio de documentos de la
/// app. El paquete `sqlite3_flutter_libs` (declarado en pubspec.yaml) provee
/// el binario nativo de SQLite en Android/iOS; no requiere import directo.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'carheva.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
