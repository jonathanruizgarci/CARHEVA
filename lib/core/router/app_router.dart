import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/catalog/presentation/screens/catalog_screen.dart';
import '../../features/catalog/presentation/screens/product_form_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/catalog',
      builder: (context, state) => const CatalogScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const ProductFormScreen(),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => ProductFormScreen(
            productId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
  ],
);
