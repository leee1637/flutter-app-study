import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warehouse_app/main.dart';

void main() {
  testWidgets('WarehouseApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WarehouseApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
