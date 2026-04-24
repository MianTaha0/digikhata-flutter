import 'package:drift/drift.dart';

import 'businesses.dart';

/// Customer/supplier records. `type`: 0 = customer, 1 = supplier.
class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  IntColumn get type => integer().withDefault(const Constant(0))();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get phone2 => text().nullable()();
  TextColumn get cnic => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  IntColumn get rating => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
