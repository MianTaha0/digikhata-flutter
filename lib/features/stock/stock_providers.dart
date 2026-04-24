import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../clients/clients_providers.dart';

final productsProvider =
    StreamProvider.autoDispose<List<Product>>((ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final bizId = await ref.watch(currentBusinessIdProvider.future);
  yield* db.productsDao.watchProducts(bizId);
});

final productByIdProvider =
    StreamProvider.autoDispose.family<Product?, int>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return db.productsDao.watchById(id);
});

final stockMovementsProvider =
    StreamProvider.autoDispose.family<List<StockMovement>, int>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return db.productsDao.watchMovementsForProduct(productId);
});
