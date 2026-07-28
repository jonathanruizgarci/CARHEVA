import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../core/sync/sync_provider.dart';
import '../core/theme/app_theme.dart';

class CarhevaApp extends ConsumerWidget {
  const CarhevaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene viva la escucha de conectividad para disparar sincronizacion
    // automatica al recuperar internet (ver core/sync/sync_provider.dart).
    ref.watch(autoSyncProvider);

    return MaterialApp.router(
      title: 'CARHEVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
