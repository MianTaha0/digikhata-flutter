import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final expensesEntriesProvider =
    StreamProvider.autoDispose<List<ExpenseEntry>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.expensesDao.watchEntries(bizId);
});

final expensesTotalProvider = StreamProvider.autoDispose<double>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.expensesDao.watchTotal(bizId);
});
