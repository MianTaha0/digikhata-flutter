import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/invoice_items.dart';
import '../tables/invoices.dart';
import '../tables/products.dart';
import '../tables/stock_movements.dart';

part 'invoices_dao.g.dart';

/// Header + items bundle, exactly the shape the form/detail screens consume.
class InvoiceWithItems {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final String customerName;
  InvoiceWithItems({
    required this.invoice,
    required this.items,
    required this.customerName,
  });

  /// Subtotal = sum of (qty * unitPrice * (1 + tax%/100)).
  double get subtotal => items.fold(
        0,
        (s, i) => s + (i.quantity * i.unitPrice) * (1 + i.taxPercent / 100),
      );

  double get discountAmount => invoice.discountIsPercent
      ? subtotal * invoice.discountValue / 100
      : invoice.discountValue;

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  double get balanceDue => (total - invoice.amountPaid)
      .clamp(0, double.infinity)
      .toDouble();
}

/// Form payload for creating/replacing an invoice's lines.
class InvoiceLineDraft {
  final String name;
  final double quantity;
  final double unitPrice;
  final double taxPercent;

  /// If non-null, this line decrements stock for that product on save.
  final int? productId;
  InvoiceLineDraft({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.taxPercent = 0,
    this.productId,
  });
}

@DriftAccessor(
  tables: [Invoices, InvoiceItems, Products, StockMovements],
)
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Stream<List<Invoice>> watchInvoices(int businessId) {
    return (select(invoices)
          ..where((t) =>
              t.businessId.equals(businessId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.issueDate)]))
        .watch();
  }

  Future<List<InvoiceItem>> itemsFor(int invoiceId) {
    return (select(invoiceItems)
          ..where((t) =>
              t.invoiceId.equals(invoiceId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<InvoiceItem>> watchItemsFor(int invoiceId) {
    return (select(invoiceItems)
          ..where((t) =>
              t.invoiceId.equals(invoiceId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Invoice?> findById(int id) =>
      (select(invoices)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Invoice?> watchById(int id) =>
      (select(invoices)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> _nextSequence(int businessId) async {
    final maxExpr = invoices.sequenceNumber.max();
    final row = await (selectOnly(invoices)
          ..addColumns([maxExpr])
          ..where(invoices.businessId.equals(businessId)))
        .getSingle();
    return (row.read(maxExpr) ?? 0) + 1;
  }

  /// Creates an invoice + items, decrements stock for every line whose
  /// `productId` is non-null. Returns the new invoice id.
  Future<int> createInvoice({
    required int businessId,
    required int customerId,
    required DateTime issueDate,
    DateTime? dueDate,
    String? notes,
    double discountValue = 0,
    bool discountIsPercent = false,
    double amountPaid = 0,
    required List<InvoiceLineDraft> lines,
  }) async {
    return transaction(() async {
      final seq = await _nextSequence(businessId);
      final id = await into(invoices).insert(InvoicesCompanion.insert(
        businessId: businessId,
        customerId: customerId,
        sequenceNumber: seq,
        issueDate: issueDate,
        dueDate: Value(dueDate),
        notes: Value(notes),
        discountValue: Value(discountValue),
        discountIsPercent: Value(discountIsPercent),
        amountPaid: Value(amountPaid),
      ));
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        await into(invoiceItems).insert(InvoiceItemsCompanion.insert(
          invoiceId: id,
          name: l.name,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          taxPercent: Value(l.taxPercent),
          sortOrder: Value(i),
        ));
        if (l.productId != null) {
          // Decrement stock and record movement.
          await customStatement(
            'UPDATE products SET quantity = quantity - ?, '
            "updated_at = strftime('%s','now') WHERE id = ?",
            [l.quantity, l.productId],
          );
          await into(stockMovements).insert(StockMovementsCompanion.insert(
            productId: l.productId!,
            delta: -l.quantity,
            reason: Value('Invoice #$seq'),
          ));
        }
      }
      return id;
    });
  }

  Future<void> updatePayment(int invoiceId, double amountPaid) {
    return (update(invoices)..where((t) => t.id.equals(invoiceId))).write(
      InvoicesCompanion(
        amountPaid: Value(amountPaid),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> softDelete(int id) =>
      (update(invoices)..where((t) => t.id.equals(id)))
          .write(InvoicesCompanion(deletedAt: Value(DateTime.now())));
}
