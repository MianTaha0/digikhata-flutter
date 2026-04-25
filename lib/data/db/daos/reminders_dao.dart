import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reminders.dart';

part 'reminders_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase>
    with _$RemindersDaoMixin {
  RemindersDao(super.db);

  Future<int> insertReminder(RemindersCompanion r) =>
      into(reminders).insert(r);

  Future<int> softDelete(int id) =>
      (update(reminders)..where((t) => t.id.equals(id)))
          .write(RemindersCompanion(deletedAt: Value(DateTime.now())));

  Future<void> markFired(int id) =>
      (update(reminders)..where((t) => t.id.equals(id)))
          .write(const RemindersCompanion(fired: Value(true)));

  Stream<List<Reminder>> watchUpcoming(int businessId) {
    return (select(reminders)
          ..where((t) =>
              t.businessId.equals(businessId) &
              t.deletedAt.isNull() &
              t.fired.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.triggerAt)]))
        .watch();
  }

  Future<List<Reminder>> pendingForBusiness(int businessId) =>
      (select(reminders)
            ..where((t) =>
                t.businessId.equals(businessId) &
                t.deletedAt.isNull() &
                t.fired.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.triggerAt)]))
          .get();
}
