import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// App-wide drift database. Disposed when the ProviderScope tears down.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
