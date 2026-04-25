import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format/money.dart';
import '../../data/db/database.dart';
import '../../data/db/daos/invoices_dao.dart';

class PdfService {
  final AppDatabase db;
  PdfService(this.db);

  static final _df = DateFormat('dd MMM yyyy');

  /// Per-client ledger PDF: chronological transactions with running balance.
  /// Balance convention: positive = client owes you.
  Future<pw.Document> buildClientStatement(int clientId) async {
    final client = await db.clientsDao.findById(clientId);
    if (client == null) {
      throw StateError('client $clientId not found');
    }
    final txs = await (db.select(db.transactions)
          ..where((t) =>
              t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.entryDate)]))
        .get();

    final doc = pw.Document();
    var running = 0.0;
    final rows = <List<String>>[];
    for (final t in txs) {
      final signed = t.type == 1 ? t.amount : -t.amount;
      running += signed;
      rows.add([
        _df.format(t.entryDate),
        t.notes ?? '',
        t.type == 0 ? formatMoney(t.amount) : '',
        t.type == 1 ? formatMoney(t.amount) : '',
        formatSigned(running),
      ]);
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Ledger Statement',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(client.name,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (client.phone != null)
                pw.Text('Phone: ${client.phone}',
                    style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Generated: ${_df.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Notes', 'You Gave', 'You Got', 'Balance'],
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Closing balance: ${formatSigned(running)}'
            '  (${running > 0 ? "owes you" : running < 0 ? "you owe" : "settled"})',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ));
    return doc;
  }

  /// Single invoice as PDF.
  Future<pw.Document> buildInvoice(int invoiceId) async {
    final inv = await db.invoicesDao.findById(invoiceId);
    if (inv == null) throw StateError('invoice $invoiceId not found');
    final items = await db.invoicesDao.itemsFor(invoiceId);
    final customer = await db.clientsDao.findById(inv.customerId);
    final bundle = InvoiceWithItems(
      invoice: inv,
      items: items,
      customerName: customer?.name ?? '—',
    );

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INVOICE',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('#${inv.sequenceNumber}',
                    style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: ${_df.format(inv.issueDate)}'),
                if (inv.dueDate != null)
                  pw.Text('Due: ${_df.format(inv.dueDate!)}'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text('Bill to:',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(bundle.customerName,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Qty', 'Unit', 'Tax%', 'Line total'],
          data: items
              .map((i) => [
                    i.name,
                    _fmtQty(i.quantity),
                    formatMoney(i.unitPrice),
                    _fmtQty(i.taxPercent),
                    formatMoney(
                        i.quantity * i.unitPrice * (1 + i.taxPercent / 100)),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          cellStyle: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _row('Subtotal', formatMoney(bundle.subtotal)),
              if (bundle.discountAmount > 0)
                _row('Discount', '-${formatMoney(bundle.discountAmount)}'),
              _row('Total', formatMoney(bundle.total), bold: true),
              _row('Paid', formatMoney(inv.amountPaid)),
              _row('Balance due', formatMoney(bundle.balanceDue), bold: true),
            ],
          ),
        ),
        if (inv.notes != null && inv.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(inv.notes!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    ));
    return doc;
  }

  static String _fmtQty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
              width: 100, child: pw.Text(label, style: style)),
          pw.SizedBox(
              width: 100,
              child:
                  pw.Text(value, style: style, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}
