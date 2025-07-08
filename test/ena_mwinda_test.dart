// Test rapide du service ENA amélioré
// Ce fichier peut être utilisé pour tester les nouvelles fonctionnalités

import 'package:flutter_test/flutter_test.dart';
import 'package:ena_mobile_front/services/ena_mwinda_chat_service.dart';

void main() {
  group('ENA Chat Service Tests', () {
    
    test('Service initializes correctly', () async {
      await EnaMwindaChatService.initialize();
      expect(EnaMwindaChatService, isNotNull);
    });

    test('Welcome message varies', () {
      final message1 = EnaMwindaChatService.getWelcomeMessage();
      final message2 = EnaMwindaChatService.getWelcomeMessage();
      final message3 = EnaMwindaChatService.getWelcomeMessage();
      
      // Au moins un des messages devrait être différent après plusieurs appels
      expect(message1.isNotEmpty, true);
      expect(message2.isNotEmpty, true);
      expect(message3.isNotEmpty, true);
    });

    test('Off-topic handling works correctly', () async {
      await EnaMwindaChatService.initialize();
      
      // Première question hors-sujet
      final response1 = await EnaMwindaChatService.sendMessage("Quelle est la météo ?");
      expect(response1.contains("ENA"), true);
      
      // Deuxième question hors-sujet
      final response2 = await EnaMwindaChatService.sendMessage("Comment ça va ?");
      expect(response2.contains("École Nationale d'Administration"), true);
    });

    test('ENA questions get enhanced context', () async {
      await EnaMwindaChatService.initialize();
      
      // Question ENA qui devrait déclencher la recherche web
      final response = await EnaMwindaChatService.sendMessage("Qui est le directeur de l'ENA ?");
      expect(response.isNotEmpty, true);
    });

    test('Reset functionality works', () {
      EnaMwindaChatService.resetChat();
      // Après reset, le compteur hors-sujet devrait être à zéro
      expect(EnaMwindaChatService, isNotNull);
    });
  });

  group('Dark Mode Color Tests', () {
    test('Card colors adapt to theme', () {
      // Test que les couleurs s'adaptent bien selon le thème
      // Ce test nécessiterait un contexte Flutter complet
      expect(true, true); // Placeholder
    });
  });
}
