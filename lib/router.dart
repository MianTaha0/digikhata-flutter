import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/backup/backup_screen.dart';
import 'features/cash/add_cash_screen.dart';
import 'features/clients/add_tx_screen.dart';
import 'features/clients/client_detail_screen.dart';
import 'features/clients/client_form_screen.dart';
import 'features/expenses/add_expense_screen.dart';
import 'features/home/home_screen.dart';
import 'features/invoices/invoice_detail_screen.dart';
import 'features/invoices/invoice_form_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/stock/product_detail_screen.dart';
import 'features/stock/product_form_screen.dart';

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
      GoRoute(
        path: '/cash/new',
        builder: (context, state) => const AddCashScreen(),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) => ProductFormScreen(
          productId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (context, state) => const InvoiceFormScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) => InvoiceDetailScreen(
          invoiceId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
    ],
  );
});
