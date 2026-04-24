import 'package:drift/drift.dart';

import 'businesses.dart';

/// Cash book entries. `type`: 0 = cash out, 1 = cash in.
class CashEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  IntColumn get type => integer()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get imageLocalPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
