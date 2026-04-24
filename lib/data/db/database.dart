import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/cash_dao.dart';
import 'daos/clients_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/products_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/businesses.dart';
import 'tables/cash_entries.dart';
import 'tables/clients.dart';
import 'tables/expense_entries.dart';
import 'tables/invoice_items.dart';
import 'tables/invoices.dart';
import 'tables/products.dart';
import 'tables/stock_movements.dart';
import 'tables/transactions.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Businesses,
    Clients,
    Transactions,
    CashEntries,
    ExpenseEntries,
    Products,
    Invoices,
    InvoiceItems,
    StockMovements,
  ],
  daos: [
    ClientsDao,
    TransactionsDao,
    CashDao,
    ExpensesDao,
    ProductsDao,
    InvoicesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cashEntries);
            await m.createTable(expenseEntries);
          }
          if (from < 3) {
            await m.createTable(products);
            await m.createTable(invoices);
            await m.createTable(invoiceItems);
            await m.createTable(stockMovements);
          }
        },
      );

  /// Ensures a default business row exists; returns its id.
  Future<int> ensureDefaultBusiness() async {
    final existing = await (select(businesses)..limit(1)).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(businesses).insert(
      BusinessesCompanion.insert(name: 'My Business'),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'digikhata.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
