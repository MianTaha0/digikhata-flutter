import 'package:drift/drift.dart';

import 'invoices.dart';

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId =>
      integer().references(Invoices, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get taxPercent => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
