import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final upcomingRemindersProvider =
    StreamProvider.autoDispose<List<Reminder>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.remindersDao.watchUpcoming(bizId);
});
