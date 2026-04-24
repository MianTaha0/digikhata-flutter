import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/clients_dao.dart';
import 'daos/transactions_dao.dart';
import 'tables/businesses.dart';
import 'tables/clients.dart';
import 'tables/transactions.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Businesses, Clients, Transactions],
  daos: [ClientsDao, TransactionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

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
