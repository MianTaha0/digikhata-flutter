import 'package:drift/drift.dart';

import 'businesses.dart';
import 'clients.dart';

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  IntColumn get customerId =>
      integer().references(Clients, #id, onDelete: KeyAction.restrict)();
  IntColumn get sequenceNumber => integer()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  BoolColumn get discountIsPercent =>
      boolean().withDefault(const Constant(false))();
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
