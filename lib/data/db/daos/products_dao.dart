import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/products.dart';
import '../tables/stock_movements.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products, StockMovements])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<int> insertProduct(ProductsCompanion p) =>
      into(products).insert(p);

  Future<bool> updateProduct(Product p) =>
      update(products).replace(p.copyWith(updatedAt: DateTime.now()));

  Future<int> softDelete(int id) =>
      (update(products)..where((t) => t.id.equals(id)))
          .write(ProductsCompanion(deletedAt: Value(DateTime.now())));

  Stream<List<Product>> watchProducts(int businessId) {
    return (select(products)
          ..where((t) =>
              t.businessId.equals(businessId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Product?> findById(int id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Product?> watchById(int id) =>
      (select(products)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Adjust quantity by delta, recording a stock movement. Negative delta = sale.
  Future<void> adjustStock({
    required int productId,
    required double delta,
    String? reason,
  }) async {
    await transaction(() async {
      final p = await findById(productId);
      if (p == null) return;
      await (update(products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(
          quantity: Value(p.quantity + delta),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await into(stockMovements).insert(StockMovementsCompanion.insert(
        productId: productId,
        delta: delta,
        reason: Value(reason),
      ));
    });
  }

  Stream<List<StockMovement>> watchMovementsForProduct(int productId) {
    return (select(stockMovements)
          ..where((t) =>
              t.productId.equals(productId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
