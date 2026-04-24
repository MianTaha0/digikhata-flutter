import 'package:digikhata/data/db/database.dart';
import 'package:digikhata/data/db/daos/invoices_dao.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int bizId;
  late int customerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bizId = await db.ensureDefaultBusiness();
    customerId = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: bizId, name: 'Acme'),
    );
  });

  tearDown(() => db.close());

  test('adjustStock writes movement and updates qty', () async {
    final id = await db.productsDao.insertProduct(ProductsCompanion.insert(
      businessId: bizId,
      name: 'Widget',
      quantity: const Value(10),
      sellPrice: const Value(50),
    ));
    await db.productsDao
        .adjustStock(productId: id, delta: -3, reason: 'Sale');
    final p = await db.productsDao.findById(id);
    expect(p!.quantity, 7);
    final moves =
        await db.productsDao.watchMovementsForProduct(id).first;
    expect(moves, hasLength(1));
    expect(moves.first.delta, -3);
  });

  test('createInvoice assigns sequence numbers per business', () async {
    final i1 = await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: customerId,
      issueDate: DateTime.now(),
      lines: [
        InvoiceLineDraft(name: 'Line A', quantity: 2, unitPrice: 50),
      ],
    );
    final i2 = await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: customerId,
      issueDate: DateTime.now(),
      lines: [
        InvoiceLineDraft(name: 'Line B', quantity: 1, unitPrice: 30),
      ],
    );
    final inv1 = await db.invoicesDao.findById(i1);
    final inv2 = await db.invoicesDao.findById(i2);
    expect(inv1!.sequenceNumber, 1);
    expect(inv2!.sequenceNumber, 2);
  });

  test('invoice with productId line decrements stock', () async {
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        businessId: bizId,
        name: 'Soap',
        quantity: const Value(20),
        sellPrice: const Value(100),
      ),
    );
    await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: customerId,
      issueDate: DateTime.now(),
      lines: [
        InvoiceLineDraft(
          name: 'Soap',
          quantity: 5,
          unitPrice: 100,
          productId: productId,
        ),
      ],
    );
    final p = await db.productsDao.findById(productId);
    expect(p!.quantity, 15);
    final moves =
        await db.productsDao.watchMovementsForProduct(productId).first;
    expect(moves, hasLength(1));
    expect(moves.first.delta, -5);
  });

  test('InvoiceWithItems totals: subtotal, discount, tax', () async {
    final id = await db.invoicesDao.createInvoice(
      businessId: bizId,
      customerId: customerId,
      issueDate: DateTime.now(),
      discountValue: 10,
      discountIsPercent: true,
      lines: [
        InvoiceLineDraft(
          name: 'A',
          quantity: 2,
          unitPrice: 100, // 200 + tax 10% = 220
          taxPercent: 10,
        ),
        InvoiceLineDraft(
          name: 'B',
          quantity: 1,
          unitPrice: 80, // 80, no tax
        ),
      ],
    );
    final inv = await db.invoicesDao.findById(id);
    final items = await db.invoicesDao.itemsFor(id);
    final w = InvoiceWithItems(
      invoice: inv!,
      items: items,
      customerName: 'Acme',
    );
    expect(w.subtotal, 300.0); // 220 + 80
    expect(w.discountAmount, 30.0); // 10% of 300
    expect(w.total, 270.0);
    expect(w.balanceDue, 270.0);
  });
}
