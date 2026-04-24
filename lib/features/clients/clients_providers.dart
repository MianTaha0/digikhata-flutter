import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos/clients_dao.dart';
import '../../data/db/daos/transactions_dao.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';

/// Current business id — M1 uses a single auto-seeded business.
final currentBusinessIdProvider = FutureProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).ensureDefaultBusiness();
});

final clientsWithBalanceProvider =
    StreamProvider.autoDispose<List<ClientWithBalance>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.clientsDao.watchClientsWithBalance(bizId);
});

final businessTotalsProvider =
    StreamProvider.autoDispose<BusinessTotals>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.transactionsDao.watchTotals(bizId);
});

final clientByIdProvider =
    StreamProvider.autoDispose.family<Client?, int>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return db.clientsDao.watchById(id);
});

final clientTransactionsProvider =
    StreamProvider.autoDispose.family<List<TxRow>, int>((ref, clientId) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionsDao.watchForClient(clientId);
});
