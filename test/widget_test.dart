// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ena_mobile_front/main.dart';
import 'package:ena_mobile_front/common/theme_provider.dart';

void main() {
  testWidgets('App builds correctly', (WidgetTester tester) async {
    // Build our app with the provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
    
    // Just check that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
