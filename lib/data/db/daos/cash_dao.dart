import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cash_entries.dart';

part 'cash_dao.g.dart';

class CashTotals {
  final double cashIn;
  final double cashOut;
  CashTotals(this.cashIn, this.cashOut);
  double get balance => cashIn - cashOut;
}

@DriftAccessor(tables: [CashEntries])
class CashDao extends DatabaseAccessor<AppDatabase> with _$CashDaoMixin {
  CashDao(super.db);

  Future<int> insertEntry(CashEntriesCompanion e) =>
      into(cashEntries).insert(e);

  Future<int> softDelete(int id) =>
      (update(cashEntries)..where((t) => t.id.equals(id))).write(
        CashEntriesCompanion(deletedAt: Value(DateTime.now())),
      );

  Stream<List<CashEntry>> watchEntries(int businessId) {
    return (select(cashEntries)
          ..where((t) =>
              t.businessId.equals(businessId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .watch();
  }

  Stream<CashTotals> watchTotals(int businessId) {
    final query = customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 1 THEN amount ELSE 0 END), 0.0) AS cin,
        COALESCE(SUM(CASE WHEN type = 0 THEN amount ELSE 0 END), 0.0) AS cout
      FROM cash_entries
      WHERE business_id = ? AND deleted_at IS NULL
      ''',
      variables: [Variable.withInt(businessId)],
      readsFrom: {cashEntries},
    );
    return query.watchSingle().map(
          (r) => CashTotals(r.read<double>('cin'), r.read<double>('cout')),
        );
  }
}
