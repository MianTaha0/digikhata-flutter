import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digikhata/app.dart';

void main() {
  testWidgets('DigiKhataApp builds and shows Home tab', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DigiKhataApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('DigiKhata'), findsOneWidget); // AppBar title
    expect(find.text('Home'), findsWidgets);        // Tab label + tab content
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
