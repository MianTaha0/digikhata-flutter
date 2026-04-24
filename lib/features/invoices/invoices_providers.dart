import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos/invoices_dao.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final invoicesProvider =
    StreamProvider.autoDispose<List<Invoice>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.invoicesDao.watchInvoices(bizId);
});

final invoiceByIdProvider =
    StreamProvider.autoDispose.family<Invoice?, int>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return db.invoicesDao.watchById(id);
});

final invoiceItemsProvider = StreamProvider.autoDispose
    .family<List<InvoiceItem>, int>((ref, invoiceId) {
  final db = ref.watch(appDatabaseProvider);
  return db.invoicesDao.watchItemsFor(invoiceId);
});

final invoiceWithItemsProvider = FutureProvider.autoDispose
    .family<InvoiceWithItems?, int>((ref, id) async {
  final db = ref.watch(appDatabaseProvider);
  final inv = await db.invoicesDao.findById(id);
  if (inv == null) return null;
  final items = await db.invoicesDao.itemsFor(id);
  final client = await db.clientsDao.findById(inv.customerId);
  return InvoiceWithItems(
    invoice: inv,
    items: items,
    customerName: client?.name ?? 'Unknown',
  );
});
