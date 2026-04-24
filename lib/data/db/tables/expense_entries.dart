import 'package:drift/drift.dart';

import 'businesses.dart';

class ExpenseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('Cash'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get imageLocalPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
