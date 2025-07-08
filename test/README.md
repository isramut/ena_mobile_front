# Tests ENA Mobile Front

Ce dossier contient les tests unitaires de l'application ENA Mobile Front.

## Fichiers de test

### `widget_test.dart`
- **Test principal** : Vérification que l'application se lance correctement
- **Fonction** : Test de base pour s'assurer que l'app compile et s'initialise sans erreur
- **Importance** : Essential - garantit que l'application démarre

### `ena_mwinda_test.dart`
- **Tests du service de chat** : Tests pour le service ENA
- **Fonctions testées** :
  - Initialisation du service
  - Messages de bienvenue variés
  - Gestion des questions hors-sujet
  - Recherche web pour les questions ENA
  - Fonctionnalité de reset du chat
- **Importance** : Important - teste une fonctionnalité clé de l'application

## Exécution des tests

Pour exécuter tous les tests :
```bash
flutter test
```

Pour exécuter un test spécifique :
```bash
flutter test test/widget_test.dart
flutter test test/ena_mwinda_test.dart
```

## Maintenance

- Les tests sont maintenus propres et sans `print` statements
- Seuls les tests essentiels et fonctionnels sont conservés
- Les fichiers de test vides ont été supprimés pour un projet plus propre
