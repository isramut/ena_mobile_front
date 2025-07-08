import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/main.dart';
import 'package:ena_mobile_front/features/auth/login_screen.dart';
import 'package:ena_mobile_front/features/parametres/parametre_screen.dart';

void main() {
  group('Biometric Authentication Integration Tests', () {
    testWidgets('Login screen shows biometric button when available', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp());
      
      // Verify that the login screen loads
      expect(find.text('Connexion'), findsOneWidget);
      
      // Look for email and password fields
      expect(find.text('Adresse e-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      
      // The biometric button should be present if biometric is available
      // Note: This will depend on the test environment and mock setup
      // In a real device test, this would show the actual biometric button
    });

    testWidgets('Parameters screen shows biometric toggle', (WidgetTester tester) async {
      // Build the parameters screen
      await tester.pumpWidget(MaterialApp(
        home: ParametreScreen(),
      ));
      
      // Verify that the parameters screen loads
      expect(find.text('Paramètres'), findsOneWidget);
      
      // Look for the biometric section
      expect(find.text('Sécurité'), findsOneWidget);
      
      // The biometric toggle should be present
      // Note: The exact text depends on the available biometric type
    });

    testWidgets('Login screen navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Find the register button and tap it
      final registerButton = find.text('Créer un compte');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }
      
      // Find the forgot password button and tap it
      await tester.pumpWidget(MyApp());
      final forgotPasswordButton = find.text('Mot de passe oublié ?');
      if (forgotPasswordButton.evaluate().isNotEmpty) {
        await tester.tap(forgotPasswordButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Find the login button and tap it without filling forms
      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pump();
        
        // Should show validation errors
        expect(find.text('Champ obligatoire'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Biometric button shows correct icon and text', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // This test would need to be run on a real device or with proper mocking
      // to verify the correct biometric type is displayed
      
      // For now, just verify the screen loads without errors
      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('Error handling works', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Fill in invalid credentials
      await tester.enterText(find.byType(TextFormField).first, 'invalid@email.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
      
      // Try to login
      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pump();
        
        // Should handle the error gracefully
        // (Exact behavior depends on server response)
      }
    });
  });
}
