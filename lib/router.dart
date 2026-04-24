import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/clients/add_tx_screen.dart';
import 'features/clients/client_detail_screen.dart';
import 'features/clients/client_form_screen.dart';
import 'features/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) => ClientDetailScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) => ClientFormScreen(
          clientId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/clients/:id/tx/new',
        builder: (context, state) => AddTxScreen(
          clientId: int.parse(state.pathParameters['id']!),
          type: int.parse(state.uri.queryParameters['type'] ?? '0'),
        ),
      ),
    ],
  );
});
