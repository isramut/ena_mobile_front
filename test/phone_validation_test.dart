import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tests de validation du téléphone', () {
    
    /// Simule la fonction de validation du téléphone
    String? validatePhoneNumber(String? value) {
      if (value == null || value.trim().isEmpty) {
        return "Numéro de téléphone requis";
      }
      
      String cleanedValue = value.trim();
      
      // Vérifier que c'est uniquement des chiffres
      if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
        return "Le téléphone ne doit contenir que des chiffres";
      }
      
      // Vérifier que c'est exactement 9 chiffres
      if (cleanedValue.length != 9) {
        return "Le téléphone doit contenir exactement 9 chiffres";
      }
      
      // Vérifier que ça ne commence pas par 0
      if (cleanedValue.startsWith('0')) {
        return "Le téléphone ne doit pas commencer par 0";
      }
      
      return null;
    }

    test('Téléphone valide (9 chiffres sans 0)', () {
      expect(validatePhoneNumber('123456789'), isNull);
      expect(validatePhoneNumber('987654321'), isNull);
      expect(validatePhoneNumber('123456780'), isNull);
    });

    test('Téléphone invalide - vide', () {
      expect(validatePhoneNumber(''), "Numéro de téléphone requis");
      expect(validatePhoneNumber(null), "Numéro de téléphone requis");
      expect(validatePhoneNumber('   '), "Numéro de téléphone requis");
    });

    test('Téléphone invalide - commence par 0', () {
      expect(validatePhoneNumber('012345678'), "Le téléphone ne doit pas commencer par 0");
      expect(validatePhoneNumber('087654321'), "Le téléphone ne doit pas commencer par 0");
    });

    test('Téléphone invalide - pas exactement 9 chiffres', () {
      expect(validatePhoneNumber('12345678'), "Le téléphone doit contenir exactement 9 chiffres");  // 8 chiffres
      expect(validatePhoneNumber('1234567890'), "Le téléphone doit contenir exactement 9 chiffres"); // 10 chiffres
      expect(validatePhoneNumber('12345'), "Le téléphone doit contenir exactement 9 chiffres");     // 5 chiffres
    });

    test('Téléphone invalide - contient des caractères non numériques', () {
      expect(validatePhoneNumber('12345678a'), "Le téléphone ne doit contenir que des chiffres");
      expect(validatePhoneNumber('123-456-789'), "Le téléphone ne doit contenir que des chiffres");
      expect(validatePhoneNumber('123 456 789'), "Le téléphone ne doit contenir que des chiffres");
      expect(validatePhoneNumber('(123)456789'), "Le téléphone ne doit contenir que des chiffres");
    });

    test('Téléphone valide avec espaces en début/fin (trim)', () {
      expect(validatePhoneNumber('  123456789  '), isNull);
      expect(validatePhoneNumber('\t123456789\n'), isNull);
    });
  });
}
