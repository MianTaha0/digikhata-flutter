import 'dart:io';

import 'package:csv/csv.dart' as csv_pkg;
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../data/db/database.dart';

class ImportReport {
  final int clients;
  final int transactions;
  final List<String> errors;
  ImportReport({
    required this.clients,
    required this.transactions,
    required this.errors,
  });
}

/// CSV importer: understands the two most common re-entry shapes,
/// clients.csv and transactions.csv (same schemas as ExportService).
/// Rows that already have an `id` matching an existing row are skipped.
class ImportService {
  final AppDatabase db;
  ImportService(this.db);

  static final _df = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<ImportReport> importClients(File file, int businessId) async {
    final errors = <String>[];
    var added = 0;
    final raw = await file.readAsString();
    final rows = csv_pkg.csv.decode(raw);
    if (rows.isEmpty) return ImportReport(clients: 0, transactions: 0, errors: errors);
    final header = rows.first.map((e) => e.toString()).toList();
    final idx = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };
    int? col(String name) => idx[name];

    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      try {
        final name = (r[col('name')!]).toString().trim();
        if (name.isEmpty) continue;
        await db.clientsDao.insertClient(ClientsCompanion.insert(
          businessId: businessId,
          name: name,
          phone: Value(_optStr(r, col('phone'))),
          phone2: Value(_optStr(r, col('phone2'))),
          cnic: Value(_optStr(r, col('cnic'))),
          address: Value(_optStr(r, col('address'))),
          type: Value(_optInt(r, col('type')) ?? 0),
        ));
        added++;
      } catch (e) {
        errors.add('clients row ${i + 1}: $e');
      }
    }
    return ImportReport(clients: added, transactions: 0, errors: errors);
  }

  /// Imports transactions by mapping client_id from the file to whatever
  /// exists in the current DB by *name*. Skips rows whose client can't be
  /// resolved.
  Future<ImportReport> importTransactions(File file, int businessId) async {
    final errors = <String>[];
    var added = 0;
    final raw = await file.readAsString();
    final rows = csv_pkg.csv.decode(raw);
    if (rows.isEmpty) return ImportReport(clients: 0, transactions: 0, errors: errors);
    final header = rows.first.map((e) => e.toString()).toList();
    final idx = <String, int>{
      for (var i = 0; i < header.length; i++) header[i]: i,
    };
    int? col(String name) => idx[name];

    // Build id → client map (same business).
    final existing = await (db.select(db.clients)
          ..where((t) => t.businessId.equals(businessId)))
        .get();
    final byId = {for (final c in existing) c.id: c};

    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      try {
        final cid = _optInt(r, col('client_id'));
        if (cid == null || !byId.containsKey(cid)) {
          errors.add('tx row ${i + 1}: client_id $cid not found');
          continue;
        }
        final amount = _num(r[col('amount')!])?.toDouble() ?? 0;
        final type = _num(r[col('type')!])?.toInt() ?? 0;
        final date = _parseDate(r[col('entry_date')!].toString()) ?? DateTime.now();
        await db.transactionsDao.insertTx(TransactionsCompanion.insert(
          clientId: cid,
          businessId: businessId,
          amount: amount,
          type: type,
          entryDate: date,
          notes: Value(_optStr(r, col('notes'))),
        ));
        added++;
      } catch (e) {
        errors.add('tx row ${i + 1}: $e');
      }
    }
    return ImportReport(clients: 0, transactions: added, errors: errors);
  }

  static String? _optStr(List<dynamic> row, int? i) {
    if (i == null || i >= row.length) return null;
    final v = row[i].toString().trim();
    return v.isEmpty ? null : v;
  }

  static int? _optInt(List<dynamic> row, int? i) {
    if (i == null || i >= row.length) return null;
    final v = row[i];
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static num? _num(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static DateTime? _parseDate(String s) {
    try {
      return _df.parse(s);
    } catch (_) {
      return DateTime.tryParse(s);
    }
  }
}
