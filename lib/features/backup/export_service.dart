import 'dart:io';

import 'package:csv/csv.dart' as csv_pkg;
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/db/database.dart';

/// Writes each table (clients, transactions, cash, expenses, invoices,
/// invoice_items) to its own CSV inside a timestamped folder.
class ExportService {
  final AppDatabase db;
  ExportService(this.db);

  static final _df = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<Directory> exportAllToCsv(int businessId) async {
    final docs = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final outDir = Directory(p.join(docs.path, 'digikhata-export-$stamp'));
    await outDir.create(recursive: true);

    await _writeClients(outDir, businessId);
    await _writeTransactions(outDir, businessId);
    await _writeCash(outDir, businessId);
    await _writeExpenses(outDir, businessId);
    await _writeInvoices(outDir, businessId);
    await _writeInvoiceItems(outDir, businessId);

    return outDir;
  }

  Future<void> _writeClients(Directory dir, int businessId) async {
    final rows = await (db.select(db.clients)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final csv = [
      ['id', 'name', 'phone', 'phone2', 'cnic', 'address', 'type',
          'credit_limit', 'rating', 'is_pinned', 'is_archived',
          'created_at', 'deleted_at'],
      ...rows.map((c) => [
            c.id,
            c.name,
            c.phone ?? '',
            c.phone2 ?? '',
            c.cnic ?? '',
            c.address ?? '',
            c.type,
            c.creditLimit,
            c.rating,
            c.isPinned ? 1 : 0,
            c.isArchived ? 1 : 0,
            _df.format(c.createdAt),
            c.deletedAt == null ? '' : _df.format(c.deletedAt!),
          ]),
    ];
    await File(p.join(dir.path, 'clients.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }

  Future<void> _writeTransactions(Directory dir, int businessId) async {
    final rows = await (db.select(db.transactions)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final csv = [
      ['id', 'client_id', 'amount', 'type', 'notes', 'entry_date',
          'created_at', 'deleted_at'],
      ...rows.map((t) => [
            t.id,
            t.clientId,
            t.amount,
            t.type,
            t.notes ?? '',
            _df.format(t.entryDate),
            _df.format(t.createdAt),
            t.deletedAt == null ? '' : _df.format(t.deletedAt!),
          ]),
    ];
    await File(p.join(dir.path, 'transactions.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }

  Future<void> _writeCash(Directory dir, int businessId) async {
    final rows = await (db.select(db.cashEntries)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final csv = [
      ['id', 'amount', 'type', 'category', 'note', 'entry_date',
          'created_at', 'deleted_at'],
      ...rows.map((e) => [
            e.id,
            e.amount,
            e.type,
            e.category,
            e.note ?? '',
            _df.format(e.entryDate),
            _df.format(e.createdAt),
            e.deletedAt == null ? '' : _df.format(e.deletedAt!),
          ]),
    ];
    await File(p.join(dir.path, 'cash_entries.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }

  Future<void> _writeExpenses(Directory dir, int businessId) async {
    final rows = await (db.select(db.expenseEntries)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final csv = [
      ['id', 'amount', 'category', 'payment_method', 'note',
          'entry_date', 'created_at', 'deleted_at'],
      ...rows.map((e) => [
            e.id,
            e.amount,
            e.category,
            e.paymentMethod,
            e.note ?? '',
            _df.format(e.entryDate),
            _df.format(e.createdAt),
            e.deletedAt == null ? '' : _df.format(e.deletedAt!),
          ]),
    ];
    await File(p.join(dir.path, 'expense_entries.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }

  Future<void> _writeInvoices(Directory dir, int businessId) async {
    final rows = await (db.select(db.invoices)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final csv = [
      ['id', 'sequence_number', 'customer_id', 'issue_date', 'due_date',
          'discount_value', 'discount_is_percent', 'amount_paid',
          'notes', 'created_at', 'deleted_at'],
      ...rows.map((i) => [
            i.id,
            i.sequenceNumber,
            i.customerId,
            _df.format(i.issueDate),
            i.dueDate == null ? '' : _df.format(i.dueDate!),
            i.discountValue,
            i.discountIsPercent ? 1 : 0,
            i.amountPaid,
            i.notes ?? '',
            _df.format(i.createdAt),
            i.deletedAt == null ? '' : _df.format(i.deletedAt!),
          ]),
    ];
    await File(p.join(dir.path, 'invoices.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }

  Future<void> _writeInvoiceItems(Directory dir, int businessId) async {
    // Only items for this business's invoices.
    final q = db.customSelect(
      '''
      SELECT ii.id, ii.invoice_id, ii.name, ii.quantity, ii.unit_price,
             ii.tax_percent, ii.sort_order
      FROM invoice_items ii
      JOIN invoices i ON i.id = ii.invoice_id
      WHERE i.business_id = ? AND ii.deleted_at IS NULL
      ORDER BY ii.invoice_id, ii.sort_order
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {db.invoiceItems, db.invoices},
    );
    final rows = await q.get();
    final csv = [
      ['id', 'invoice_id', 'name', 'quantity', 'unit_price',
          'tax_percent', 'sort_order'],
      ...rows.map((r) => [
            r.read<int>('id'),
            r.read<int>('invoice_id'),
            r.read<String>('name'),
            r.read<double>('quantity'),
            r.read<double>('unit_price'),
            r.read<double>('tax_percent'),
            r.read<int>('sort_order'),
          ]),
    ];
    await File(p.join(dir.path, 'invoice_items.csv'))
        .writeAsString(csv_pkg.csv.encode(csv));
  }
}
