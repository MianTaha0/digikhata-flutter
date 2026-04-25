import 'package:digikhata/data/db/database.dart';
import 'package:digikhata/data/db/daos/invoices_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int bizId;
  late int c1;
  late int c2;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bizId = await db.ensureDefaultBusiness();
    c1 = await db.clientsDao
        .insertClient(ClientsCompanion.insert(businessId: bizId, name: 'Ali'));
    c2 = await db.clientsDao
        .insertClient(ClientsCompanion.insert(businessId: bizId, name: 'Ben'));
  });

  tearDown(() => db.close());

  test('snapshot sums cash + receivable + expense + invoice revenue',
      () async {
    await db.cashDao.insertEntry(CashEntriesCompanion.insert(
      businessId: bizId,
      amount: 500,
      type: 1,
      entryDate: DateTime.now(),
    ));
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: c1,
      businessId: bizId,
      amount: 300,
      type: 1, // got
      entryDate: DateTime.now(),
    ));
    await db.expensesDao.insertEntry(ExpenseEntriesCompanion.insert(
      businessId: bizId,
      amount: 120,
      category: 'Food',
      entryDate: DateTime.now(),
    ));
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: c1,
      issueDate: DateTime.now(),
      lines: [
        InvoiceLineDraft(name: 'A', quantity: 2, unitPrice: 100),
      ],
    );
    final snap = await db.reportsDao.snapshot(bizId);
    expect(snap.cashInHand, 500.0);
    expect(snap.totalReceivable, 300.0);
    expect(snap.totalPayable, 0.0);
    expect(snap.totalExpenses, 120.0);
    expect(snap.invoiceRevenue, 200.0);
    expect(snap.invoiceCount, 1);
  });

  test('last30DaysSales bucketed by day, zeroed where empty', () async {
    final today = DateTime.now();
    // Older invoice (today)
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: c1,
      issueDate: today,
      lines: [
        InvoiceLineDraft(name: 'x', quantity: 1, unitPrice: 50),
      ],
    );
    final points = await db.reportsDao.last30DaysSales(bizId);
    expect(points, hasLength(30));
    expect(points.last.total, 50.0); // today's bucket
    expect(points.first.total, 0.0); // 29 days ago
  });

  test('topCustomers ranks by revenue, excludes zero', () async {
    // c1 -> 200, c2 -> 500
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: c1,
      issueDate: DateTime.now(),
      lines: [InvoiceLineDraft(name: 'a', quantity: 2, unitPrice: 100)],
    );
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: c2,
      issueDate: DateTime.now(),
      lines: [InvoiceLineDraft(name: 'b', quantity: 5, unitPrice: 100)],
    );
    final top = await db.reportsDao.topCustomers(bizId);
    expect(top, hasLength(2));
    expect(top.first.name, 'Ben');
    expect(top.first.totalSales, 500.0);
    expect(top[1].name, 'Ali');
  });
}
