import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digikhata/app.dart';
import 'package:digikhata/data/db/database.dart';
import 'package:digikhata/data/db/database_provider.dart';

void main() {
  testWidgets('DigiKhataApp builds and shows Home with clients list',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const DigiKhataApp(),
      ),
    );
    // A few pumps to let initial stream values arrive. We avoid pumpAndSettle
    // because drift's stream keeps a long-lived subscription timer.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('DigiKhata'), findsOneWidget); // AppBar title
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Add customer'), findsOneWidget); // FAB label

    // Unmount the tree so autoDispose stream subscriptions cancel before
    // the drift database is closed in addTearDown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
