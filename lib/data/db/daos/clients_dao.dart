import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/clients.dart';
import '../tables/transactions.dart';

part 'clients_dao.g.dart';

/// Client row + running balance (sum of `got` minus `gave`, positive = client owes you).
class ClientWithBalance {
  final Client client;
  final double balance;
  ClientWithBalance(this.client, this.balance);
}

@DriftAccessor(tables: [Clients, Transactions])
class ClientsDao extends DatabaseAccessor<AppDatabase> with _$ClientsDaoMixin {
  ClientsDao(super.db);

  Future<int> insertClient(ClientsCompanion c) => into(clients).insert(c);

  Future<bool> updateClient(Client c) =>
      update(clients).replace(c.copyWith(updatedAt: DateTime.now()));

  Future<int> softDelete(int id) => (update(clients)..where((t) => t.id.equals(id)))
      .write(ClientsCompanion(deletedAt: Value(DateTime.now())));

  Stream<List<ClientWithBalance>> watchClientsWithBalance(int businessId) {
    final balance = transactions.amount.sum(
      filter: transactions.deletedAt.isNull() &
          transactions.type.equals(1),
    );
    final gaveSum = transactions.amount.sum(
      filter: transactions.deletedAt.isNull() &
          transactions.type.equals(0),
    );
    final query = select(clients).join([
      leftOuterJoin(transactions, transactions.clientId.equalsExp(clients.id)),
    ])
      ..where(clients.businessId.equals(businessId) &
          clients.deletedAt.isNull())
      ..groupBy([clients.id])
      ..orderBy([
        OrderingTerm.desc(clients.isPinned),
        OrderingTerm.asc(clients.name),
      ])
      ..addColumns([balance, gaveSum]);
    return query.watch().map((rows) => rows.map((r) {
          final got = r.read(balance) ?? 0.0;
          final gave = r.read(gaveSum) ?? 0.0;
          return ClientWithBalance(r.readTable(clients), got - gave);
        }).toList());
  }

  Future<Client?> findById(int id) =>
      (select(clients)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Client?> watchById(int id) =>
      (select(clients)..where((t) => t.id.equals(id))).watchSingleOrNull();
}
