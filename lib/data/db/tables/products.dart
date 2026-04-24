import 'package:drift/drift.dart';

import 'businesses.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get businessId =>
      integer().references(Businesses, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  TextColumn get imageLocalPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
