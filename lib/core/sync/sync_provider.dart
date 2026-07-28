import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_provider.dart';
import 'connectivity_provider.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(appDatabaseProvider), Supabase.instance.client);
});

/// Dispara `syncNow()` automaticamente cada vez que el dispositivo recupera
/// conexion. Debe mantenerse "vivo" (ver `ref.listen` en el widget raiz de
/// la app) para que seguir escuchando cambios de conectividad.
final autoSyncProvider = Provider<void>((ref) {
  var wasOnline = true;

  ref.listen(isOnlineProvider, (previous, next) {
    final isOnline = next.valueOrNull ?? false;
    if (isOnline && !wasOnline) {
      ref.read(syncServiceProvider).syncNow();
    }
    wasOnline = isOnline;
  });
});
