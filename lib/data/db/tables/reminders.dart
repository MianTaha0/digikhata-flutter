import 'package:drift/drift.dart';

import 'businesses.dart';
import 'clients.dart';

/// A scheduled reminder.
/// `kind`: 0 = balance check, 1 = invoice due, 2 = custom.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer()
      .nullable()
      .references(Clients, #id, onDelete: KeyAction.cascade)();
  IntColumn get invoiceId => integer().nullable()();
  IntColumn get kind => integer().withDefault(const Constant(0))();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get triggerAt => dateTime()();
  BoolColumn get fired => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
