# Format du Numéro de Téléphone - Candidature ENA

## 📋 Spécifications

### Format pour l'API Backend
- **Format**: `{indicatif}{numéro}` (sans espace)
- **Exemple**: `+243123456789`
- **Validation**: 
  - Indicatif: `+243`, `+33`, `+32`, `+1`, `+44`
  - Numéro: exactement 9 chiffres, ne commence pas par 0

### Format d'affichage
- **Récapitulatif**: Cohérent avec l'API (sans espace)
- **PDF**: Indicatif et numéro stockés séparément, formatage géré par le service PDF

## 🔧 Implémentation

### Dans candidature_process_screen.dart

#### Envoi API (ligne 2291)
```dart
"telephone": "$indicatif${telephoneController.text}",
```

#### Affichage récapitulatif (ligne 1987)
```dart
ligne(
  "Téléphone",
  "$indicatif${telephoneController.text}",
),
```

#### Génération PDF (lignes 2574-2575)
```dart
indicatif: indicatif,
telephone: telephoneController.text,
```

## ✅ Validation

### Critères de validation (_validatePhoneNumber)
1. **Obligatoire**: Le champ ne peut pas être vide
2. **Chiffres uniquement**: Contient seulement des chiffres (0-9)
3. **Longueur exacte**: Exactement 9 chiffres
4. **Pas de zéro initial**: Ne commence pas par 0

### Exemples valides
- ✅ `123456789` → `+243123456789`
- ✅ `987654321` → `+243987654321`
- ✅ `555123456` → `+243555123456`

### Exemples invalides
- ❌ `0123456789` (commence par 0)
- ❌ `12345678` (8 chiffres seulement)
- ❌ `12345678a` (contient une lettre)
- ❌ `123 456 789` (contient des espaces)

## 🧪 Tests

Voir `test/phone_format_test.dart` pour les tests unitaires validant :
- Le format de l'API sans espace
- La cohérence entre affichage et API
- La validation des différents indicatifs
- La gestion des cas limites

## 📱 Interface Utilisateur

### Champ de saisie
- **Placeholder**: "Ex: 123456789 (9 chiffres, sans 0)"
- **Aide**: "Format: 9 chiffres sans le 0 initial"
- **Type de clavier**: Numérique
- **Longueur max**: 9 caractères

### Indicatif séparé
- **Dropdown** avec les indicatifs supportés
- **Valeur par défaut**: "+243" (RDC)
- **Affichage**: Séparé visuellement du numéro principal

## 🔄 Workflow de validation

1. **Saisie utilisateur**: Numéro dans le champ téléphone (9 chiffres)
2. **Validation**: Vérification des critères obligatoires
3. **Combinaison**: Assemblage indicatif + numéro sans espace
4. **Envoi API**: Format final `+243123456789`
5. **Confirmation**: Affichage cohérent dans le récapitulatif

## 📚 Références

- **Fichier principal**: `lib/features/apply/candidature_process_screen.dart`
- **Validation**: Méthode `_validatePhoneNumber()` (ligne 260)
- **Tests**: `test/phone_format_test.dart`
- **Modèle PDF**: `lib/models/candidature_pdf_data.dart`
