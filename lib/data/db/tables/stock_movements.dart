import 'package:drift/drift.dart';

import 'products.dart';

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  RealColumn get delta => real()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
