import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos/cash_dao.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final cashEntriesProvider =
    StreamProvider.autoDispose<List<CashEntry>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.cashDao.watchEntries(bizId);
});

final cashTotalsProvider = StreamProvider.autoDispose<CashTotals>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.cashDao.watchTotals(bizId);
});
