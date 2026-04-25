import 'dart:io';

import 'package:digikhata/data/db/database.dart';
import 'package:digikhata/features/backup/export_service.dart';
import 'package:digikhata/features/backup/import_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TmpPathProvider extends PathProviderPlatform {
  final String tmp;
  _TmpPathProvider(this.tmp);
  @override
  Future<String?> getApplicationDocumentsPath() async => tmp;
  @override
  Future<String?> getTemporaryPath() async => tmp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int bizId;
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('digikhata-test');
    PathProviderPlatform.instance = _TmpPathProvider(tmp.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bizId = await db.ensureDefaultBusiness();
  });

  tearDown(() async {
    await db.close();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('export writes all six CSVs', () async {
    final cId = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: bizId, name: 'Ali'),
    );
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: cId,
      businessId: bizId,
      amount: 250,
      type: 1,
      entryDate: DateTime.now(),
    ));

    final out = await ExportService(db).exportAllToCsv(bizId);
    final names = out.listSync().map((f) => p.basename(f.path)).toSet();
    expect(
      names,
      containsAll(<String>[
        'clients.csv',
        'transactions.csv',
        'cash_entries.csv',
        'expense_entries.csv',
        'invoices.csv',
        'invoice_items.csv',
      ]),
    );
    final clients = File(p.join(out.path, 'clients.csv')).readAsStringSync();
    expect(clients, contains('Ali'));
  });

  test('import clients then transactions round-trips from export', () async {
    final cId = await db.clientsDao.insertClient(
      ClientsCompanion.insert(businessId: bizId, name: 'Ali'),
    );
    await db.transactionsDao.insertTx(TransactionsCompanion.insert(
      clientId: cId,
      businessId: bizId,
      amount: 100,
      type: 1,
      entryDate: DateTime.now(),
    ));
    final out = await ExportService(db).exportAllToCsv(bizId);

    // Fresh DB — reimport both files
    final db2 = AppDatabase.forTesting(NativeDatabase.memory());
    final bizId2 = await db2.ensureDefaultBusiness();
    try {
      final svc = ImportService(db2);
      final r1 =
          await svc.importClients(File(p.join(out.path, 'clients.csv')), bizId2);
      expect(r1.clients, 1);
      final r2 = await svc.importTransactions(
          File(p.join(out.path, 'transactions.csv')), bizId2);
      expect(r2.transactions, 1,
          reason: 'errors: ${r2.errors.join("; ")}');
    } finally {
      await db2.close();
    }
  });
}
