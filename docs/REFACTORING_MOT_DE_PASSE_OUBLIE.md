# Refactoring du flux "Mot de passe oublié" - Documentation

## Objectif
Simplifier le flux de réinitialisation de mot de passe pour n'utiliser que 2 endpoints au lieu de 3, en éliminant l'étape de vérification OTP séparée.

## Ancien flux (3 étapes, 3 endpoints)
1. **ForgotPasswordScreen** → `POST /forgot-password` (envoi OTP)
2. **PasswordRecuperationScreen** → `POST /otp` (vérification OTP)
3. **NewPasswordScreen** → `POST /reset-password` (nouveau mot de passe)

## Nouveau flux (2 étapes, 2 endpoints)
1. **ForgotPasswordScreen** → `POST /forgot-password` (envoi OTP)
2. **NewPasswordScreen** → `POST /reset-password` (OTP + nouveau mot de passe)

## Modifications apportées

### 1. ForgotPasswordScreen (`forgot_password_screen.dart`)
- **Changement** : Redirection directe vers `NewPasswordScreen` avec `isResetFlow = true`
- **Suppression** : Navigation vers `PasswordRecuperationScreen`
- **Import** : Remplacement de `email_verify.dart` par `new_password.dart`

### 2. NewPasswordScreen (`new_password.dart`)
- **Ajout** : Paramètre `isResetFlow` pour distinguer les flux
- **Ajout** : Champ de saisie OTP quand `isResetFlow = true`
- **Ajout** : Méthode `_resendCode()` pour renvoyer le code
- **Ajout** : Interface Scaffold complet pour le nouveau flux (au lieu de Dialog)
- **Modification** : Logique de navigation selon le flux
- **Modification** : Titre et description adaptés selon le flux

### 3. AuthApiService (`auth_api_service.dart`)
- **Modification** : Commentaire sur `verifyOtp()` pour clarifier qu'elle n'est utilisée que pour l'inscription
- **Conservation** : Les méthodes `forgotPassword()` et `resetPassword()` restent inchangées

## Comportement par flux

### Nouveau flux de réinitialisation (`isResetFlow = true`)
1. Écran complet avec AppBar
2. Champ OTP obligatoire (6 chiffres)
3. Champ nouveau mot de passe avec validation de force
4. Champ confirmation mot de passe
5. Bouton "Renvoyer le code" qui appelle `forgotPassword()`
6. Navigation directe vers LoginScreen après succès

### Ancien flux (Dialog, `isResetFlow = false`)
1. Pop-up Dialog
2. Pas de champ OTP (l'OTP est passé en paramètre)
3. Champ nouveau mot de passe avec validation
4. Bouton "Annuler" disponible
5. Fermeture de la pop-up puis navigation vers LoginScreen

## Validation et sécurité
- Validation OTP : 6 chiffres exactement
- Validation mot de passe : force "strong" requise
- Gestion d'erreurs : messages explicites pour chaque type d'erreur
- Logs de debug conservés pour le troubleshooting

## Endpoints utilisés
- `POST /api/users/forgot-password/` : Envoi du code OTP par email
- `POST /api/users/reset-password/` : Réinitialisation avec OTP + nouveau mot de passe

## Avantages du nouveau flux
1. **Simplicité** : Moins d'écrans et d'étapes
2. **Performance** : Moins d'appels API
3. **UX** : Flux plus direct et intuitif
4. **Maintenance** : Code plus simple à maintenir
5. **Sécurité** : Validation directe OTP + mot de passe en une seule requête

## Tests recommandés
1. ✅ Saisie email valide → Réception code OTP
2. ✅ Saisie OTP invalide → Message d'erreur approprié
3. ✅ Saisie mot de passe faible → Refus avec message
4. ✅ Renvoyer code → Nouveau code reçu
5. ✅ Réinitialisation réussie → Redirection vers login
6. ✅ Test sur erreurs réseau
7. ✅ Test de l'ancien flux (inscription) → Pas d'impact

## Rétrocompatibilité
- L'ancien flux d'inscription via `PasswordRecuperationScreen` reste fonctionnel
- La méthode `verifyOtp()` est conservée pour l'inscription
- Aucun impact sur les autres parties de l'application

## État
- ✅ Refactoring terminé
- ✅ Code testé et validé
- ✅ Documentation mise à jour
- 🔄 Tests utilisateur à effectuer

Date de création : 9 juillet 2025
