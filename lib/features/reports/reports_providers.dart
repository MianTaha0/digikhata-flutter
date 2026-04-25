import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos/reports_dao.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final snapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  return db.reportsDao.snapshot(bizId);
});

final dailySalesProvider =
    FutureProvider.autoDispose<List<DailySalesPoint>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  return db.reportsDao.last30DaysSales(bizId);
});

final topCustomersProvider =
    FutureProvider.autoDispose<List<TopCustomer>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  return db.reportsDao.topCustomers(bizId);
});
