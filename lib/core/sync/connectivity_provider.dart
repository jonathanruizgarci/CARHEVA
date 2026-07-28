import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emite true/false cada vez que cambia la conectividad del dispositivo.
/// La UI puede usarlo para mostrar un indicador "sin conexion", y el
/// SyncService lo usa para disparar sincronizacion automatica al reconectar.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});
