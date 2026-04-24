import 'package:digikhata/data/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int bizId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bizId = await db.ensureDefaultBusiness();
  });

  tearDown(() => db.close());

  test('cash totals compute in/out/balance', () async {
    await db.cashDao.insertEntry(CashEntriesCompanion.insert(
      businessId: bizId,
      amount: 1000,
      type: 1, // in
      entryDate: DateTime.now(),
    ));
    await db.cashDao.insertEntry(CashEntriesCompanion.insert(
      businessId: bizId,
      amount: 300,
      type: 0, // out
      entryDate: DateTime.now(),
    ));
    final t = await db.cashDao.watchTotals(bizId).first;
    expect(t.cashIn, 1000.0);
    expect(t.cashOut, 300.0);
    expect(t.balance, 700.0);
  });

  test('soft-deleted cash entry excluded', () async {
    final id = await db.cashDao.insertEntry(CashEntriesCompanion.insert(
      businessId: bizId,
      amount: 500,
      type: 1,
      entryDate: DateTime.now(),
    ));
    await db.cashDao.softDelete(id);
    final t = await db.cashDao.watchTotals(bizId).first;
    expect(t.cashIn, 0.0);
    final list = await db.cashDao.watchEntries(bizId).first;
    expect(list, isEmpty);
  });

  test('expenses total sums only non-deleted rows', () async {
    await db.expensesDao.insertEntry(ExpenseEntriesCompanion.insert(
      businessId: bizId,
      amount: 120,
      category: 'Food',
      entryDate: DateTime.now(),
    ));
    final id = await db.expensesDao.insertEntry(ExpenseEntriesCompanion.insert(
      businessId: bizId,
      amount: 80,
      category: 'Transport',
      entryDate: DateTime.now(),
    ));
    expect(await db.expensesDao.watchTotal(bizId).first, 200.0);
    await db.expensesDao.softDelete(id);
    expect(await db.expensesDao.watchTotal(bizId).first, 120.0);
  });
}
