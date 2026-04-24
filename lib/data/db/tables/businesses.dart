import 'package:drift/drift.dart';

/// Placeholder table so drift codegen has something to generate against.
/// Real columns (ownerName, currency, etc.) get added in M1.
class Businesses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
