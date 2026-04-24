import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/expense_entries.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [ExpenseEntries])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<int> insertEntry(ExpenseEntriesCompanion e) =>
      into(expenseEntries).insert(e);

  Future<int> softDelete(int id) =>
      (update(expenseEntries)..where((t) => t.id.equals(id))).write(
        ExpenseEntriesCompanion(deletedAt: Value(DateTime.now())),
      );

  Stream<List<ExpenseEntry>> watchEntries(int businessId) {
    return (select(expenseEntries)
          ..where((t) =>
              t.businessId.equals(businessId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.entryDate)]))
        .watch();
  }

  Stream<double> watchTotal(int businessId) {
    final sum = expenseEntries.amount.sum();
    final q = selectOnly(expenseEntries)
      ..addColumns([sum])
      ..where(expenseEntries.businessId.equals(businessId) &
          expenseEntries.deletedAt.isNull());
    return q.watchSingle().map((r) => r.read(sum) ?? 0.0);
  }
}
