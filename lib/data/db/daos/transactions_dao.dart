import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/transactions.dart';

part 'transactions_dao.g.dart';

class BusinessTotals {
  final double youGave;
  final double youGot;
  BusinessTotals(this.youGave, this.youGot);
  double get net => youGot - youGave;
}

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<int> insertTx(TransactionsCompanion t) => into(transactions).insert(t);

  Future<int> softDelete(int id) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(deletedAt: Value(DateTime.now())),
      );

  Stream<List<TxRow>> watchForClient(int clientId) {
    return (select(transactions)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .watch();
  }

  Stream<BusinessTotals> watchTotals(int businessId) {
    final query = customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 0 THEN amount ELSE 0 END), 0.0) AS gave,
        COALESCE(SUM(CASE WHEN type = 1 THEN amount ELSE 0 END), 0.0) AS got
      FROM transactions
      WHERE business_id = ? AND deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {transactions},
    );
    return query.watchSingle().map(
          (r) => BusinessTotals(r.read<double>('gave'), r.read<double>('got')),
        );
  }
}
