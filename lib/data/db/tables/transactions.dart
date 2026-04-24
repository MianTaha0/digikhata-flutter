import 'package:drift/drift.dart';

import 'businesses.dart';
import 'clients.dart';

/// Ledger entries. `type`: 0 = you gave (debit/credit out), 1 = you got.
@DataClassName('TxRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clientId =>
      integer().references(Clients, #id, onDelete: KeyAction.cascade)();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  IntColumn get type => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get imageLocalPath => text().nullable()();
  IntColumn get imagesCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
