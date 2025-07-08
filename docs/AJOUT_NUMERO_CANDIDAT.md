# Ajout du numéro candidat dans le PDF de candidature

## Résumé des modifications

Cette mise à jour ajoute le numéro candidat de l'utilisateur connecté dans le PDF généré lors de la soumission de candidature.

## Changements effectués

### 1. Modèle de données `CandidaturePdfData`
- **Fichier** : `lib/models/candidature_pdf_data.dart`
- **Changement** : Ajout du champ `numero` (optionnel) pour stocker le numéro de candidat

```dart
final String? numero;  // Nouveau champ ajouté

CandidaturePdfData({
  // ... autres paramètres
  this.numero,  // Paramètre optionnel ajouté
});
```

### 2. Template PDF `FicheSoumissionTemplate`
- **Fichier** : `lib/templates/fiche_soumission_template.dart`
- **Changements** :
  - Correction du logo ENA (utilisation du logo normal au lieu du logo blanc)
  - Ajout de l'affichage du numéro candidat centré sous le titre
  - Nouvelle méthode `_buildNumeroCandidat()` pour afficher le numéro

```dart
// Logo ENA normal (pas blanc) selon spécifications
final logoBytes = await rootBundle.load('assets/images/ena_logo.png');

// Affichage du numéro candidat si disponible
if (data.numero != null && data.numero!.isNotEmpty)
  _buildNumeroCandidat(data.numero!),
```

### 3. Service de candidature `CandidatureProcessScreen`
- **Fichier** : `lib/features/apply/candidature_process_screen.dart`
- **Changements** :
  - Ajout de l'import du service d'authentification
  - Modification de `_preparePdfData()` pour récupérer le numéro candidat via l'API utilisateur
  - Récupération sécurisée du numéro depuis `/api/users/user-info/`

```dart
// Récupérer le numéro de candidat depuis les informations utilisateur
String? numeroCandidat;
try {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token != null) {
    final result = await AuthApiService.getUserInfo(token: token);
    if (result['success'] == true && result['data'] != null) {
      numeroCandidat = result['data']['numero'];
    }
  }
} catch (e) {
  // Ignorer l'erreur silencieusement
}

return CandidaturePdfData(
  // ... autres champs
  numero: numeroCandidat, // Numéro de candidat récupéré de l'API
);
```

### 4. Tests mis à jour
- **Fichiers** : 
  - `test/pdf_generation_test.dart`
- **Changement** : Ajout du champ `numero` dans les données de test

```dart
testData = CandidaturePdfData(
  // ... autres champs
  numero: 'ENA2024001', // Numéro de candidat pour les tests
);
```

## Structure du PDF mise à jour

Le PDF généré respecte maintenant strictement les spécifications :

1. **Header** : Logo ENA (2,26 cm * 9,25 cm) à gauche, Badge gouvernemental (2,61 cm * 2,76 cm) à droite
2. **Titre centré** : "FICHE DE CANDIDATURE"
3. **Numéro candidat** : Affiché centré sous le titre (si disponible)
4. **Contenu** : Toutes les données utilisateur organisées par sections
5. **Footer** : Informations ENA et date/heure de génération

## Source des données

Le numéro candidat est récupéré du champ `numero` du payload de l'endpoint `/api/users/user-info/` qui est déjà intégré dans le modèle `UserInfo`.

## Gestion des erreurs

- Si l'API n'est pas accessible, le PDF est généré sans le numéro candidat
- Si le numéro n'existe pas ou est vide, il n'est pas affiché
- Aucune erreur n'est affichée à l'utilisateur en cas de problème de récupération

## Tests

- Les tests unitaires ont été mis à jour pour inclure des numéros candidat fictifs
- Le projet compile sans erreur
- Tous les imports et dépendances sont correctement configurés
