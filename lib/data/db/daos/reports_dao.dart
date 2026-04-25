import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cash_entries.dart';
import '../tables/clients.dart';
import '../tables/expense_entries.dart';
import '../tables/invoice_items.dart';
import '../tables/invoices.dart';
import '../tables/transactions.dart';

part 'reports_dao.g.dart';

class DailySalesPoint {
  final DateTime day;
  final double total;
  DailySalesPoint(this.day, this.total);
}

class TopCustomer {
  final int clientId;
  final String name;
  final double totalSales;
  TopCustomer(this.clientId, this.name, this.totalSales);
}

class DashboardSnapshot {
  final double cashInHand;
  final double totalReceivable; // clients owe you
  final double totalPayable; // you owe clients
  final double totalExpenses;
  final double invoiceRevenue;
  final int invoiceCount;
  DashboardSnapshot({
    required this.cashInHand,
    required this.totalReceivable,
    required this.totalPayable,
    required this.totalExpenses,
    required this.invoiceRevenue,
    required this.invoiceCount,
  });
}

@DriftAccessor(tables: [
  Invoices,
  InvoiceItems,
  Clients,
  Transactions,
  CashEntries,
  ExpenseEntries,
])
class ReportsDao extends DatabaseAccessor<AppDatabase>
    with _$ReportsDaoMixin {
  ReportsDao(super.db);

  /// Last [days] days of invoice revenue, one point per day, oldest first.
  /// Days with no invoices return 0.
  Future<List<DailySalesPoint>> last30DaysSales(int businessId,
      {int days = 30}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    // Query invoices in range; compute daily subtotals from invoice_items.
    final rows = await customSelect(
      '''
      SELECT i.issue_date AS issue_date,
             ii.quantity * ii.unit_price * (1 + ii.tax_percent / 100.0) AS line_total
      FROM invoices i
      JOIN invoice_items ii ON ii.invoice_id = i.id AND ii.deleted_at IS NULL
      WHERE i.business_id = ?
        AND i.deleted_at IS NULL
        AND i.issue_date >= ?
      ''',
      variables: [
        Variable.withInt(businessId),
        Variable.withDateTime(start),
      ],
      readsFrom: {invoices, invoiceItems},
    ).get();

    final buckets = <DateTime, double>{
      for (var i = 0; i < days; i++)
        start.add(Duration(days: i)): 0.0,
    };
    for (final r in rows) {
      final issue = r.read<DateTime>('issue_date');
      final day = DateTime(issue.year, issue.month, issue.day);
      final total = r.read<double>('line_total');
      buckets[day] = (buckets[day] ?? 0) + total;
    }
    return buckets.entries
        .map((e) => DailySalesPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  /// Top-N customers by total invoice revenue.
  Future<List<TopCustomer>> topCustomers(int businessId,
      {int limit = 5}) async {
    final rows = await customSelect(
      '''
      SELECT c.id AS client_id, c.name AS name,
             COALESCE(SUM(ii.quantity * ii.unit_price * (1 + ii.tax_percent / 100.0)), 0) AS total
      FROM clients c
      LEFT JOIN invoices i ON i.customer_id = c.id AND i.deleted_at IS NULL
      LEFT JOIN invoice_items ii ON ii.invoice_id = i.id AND ii.deleted_at IS NULL
      WHERE c.business_id = ? AND c.deleted_at IS NULL
      GROUP BY c.id
      HAVING total > 0
      ORDER BY total DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(businessId),
        Variable.withInt(limit),
      ],
      readsFrom: {clients, invoices, invoiceItems},
    ).get();
    return rows
        .map((r) => TopCustomer(
              r.read<int>('client_id'),
              r.read<String>('name'),
              r.read<double>('total'),
            ))
        .toList();
  }

  Future<DashboardSnapshot> snapshot(int businessId) async {
    final cash = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 1 THEN amount ELSE -amount END), 0) AS balance
      FROM cash_entries
      WHERE business_id = ? AND deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {cashEntries},
    ).getSingle();

    final rec = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 1 THEN amount ELSE -amount END), 0) AS net
      FROM transactions
      WHERE business_id = ? AND deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {transactions},
    ).getSingle();
    final net = rec.read<double>('net');

    final exp = await customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expense_entries
      WHERE business_id = ? AND deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {expenseEntries},
    ).getSingle();

    final inv = await customSelect(
      '''
      SELECT COUNT(DISTINCT i.id) AS cnt,
             COALESCE(SUM(ii.quantity * ii.unit_price * (1 + ii.tax_percent / 100.0)), 0) AS revenue
      FROM invoices i
      LEFT JOIN invoice_items ii ON ii.invoice_id = i.id AND ii.deleted_at IS NULL
      WHERE i.business_id = ? AND i.deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {invoices, invoiceItems},
    ).getSingle();

    return DashboardSnapshot(
      cashInHand: cash.read<double>('balance'),
      totalReceivable: net > 0 ? net : 0,
      totalPayable: net < 0 ? -net : 0,
      totalExpenses: exp.read<double>('total'),
      invoiceRevenue: inv.read<double>('revenue'),
      invoiceCount: inv.read<int>('cnt'),
    );
  }
}
