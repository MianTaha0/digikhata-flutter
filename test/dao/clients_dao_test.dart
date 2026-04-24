import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digikhata/data/db/database.dart';
import 'package:digikhata/data/db/tables/clients.dart';
import 'package:digikhata/data/db/tables/transactions.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;
  late int businessId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    businessId = await db.ensureDefaultBusiness();
  });

  tearDown(() async => db.close());

  test('watchClientsWithBalance reports zero balance for client with no tx',
      () async {
    final id = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'Ali'),
    );
    final rows = await db.clientsDao.watchClientsWithBalance(businessId).first;
    expect(rows, hasLength(1));
    expect(rows.single.client.id, id);
    expect(rows.single.balance, 0.0);
  });

  test('watchClientsWithBalance nets gave/got correctly', () async {
    final id = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'Ali'),
    );
    // gave 500, got 300 -> balance = 300 - 500 = -200 (you owe client)
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: id,
      businessId: businessId,
      amount: 500,
      type: 0,
      entryDate: DateTime.now(),
    ));
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: id,
      businessId: businessId,
      amount: 300,
      type: 1,
      entryDate: DateTime.now(),
    ));
    final rows = await db.clientsDao.watchClientsWithBalance(businessId).first;
    expect(rows.single.balance, -200.0);
  });

  test('watchTotals sums gave + got across all clients', () async {
    final a = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'A'),
    );
    final b = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'B'),
    );
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: a,
      businessId: businessId,
      amount: 100,
      type: 0,
      entryDate: DateTime.now(),
    ));
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: b,
      businessId: businessId,
      amount: 40,
      type: 1,
      entryDate: DateTime.now(),
    ));
    final totals = await db.transactionsDao.watchTotals(businessId).first;
    expect(totals.youGave, 100.0);
    expect(totals.youGot, 40.0);
    expect(totals.net, -60.0);
  });

  test('soft-deleted tx excluded from balance', () async {
    final id = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'Ali'),
    );
    final txId = await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: id,
      businessId: businessId,
      amount: 500,
      type: 0,
      entryDate: DateTime.now(),
    ));
    await db.transactionsDao.softDelete(txId);
    final rows = await db.clientsDao.watchClientsWithBalance(businessId).first;
    expect(rows.single.balance, 0.0);
  });

  test('pinned clients sort first', () async {
    await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: businessId, name: 'Zara'),
    );
    await db.clientsDao.insertClient(ClientsCompanion.insert(
      businessId: businessId,
      name: 'Ali',
      isPinned: const Value(true),
    ));
    final rows = await db.clientsDao.watchClientsWithBalance(businessId).first;
    expect(rows.map((r) => r.client.name).toList(), ['Ali', 'Zara']);
  });
}
