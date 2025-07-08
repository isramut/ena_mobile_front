# Tests de Persistance Biométrique

## Tests à effectuer après les corrections

### 1. Test de persistance après logout
1. **Activer la biométrie** dans les paramètres
2. **Se connecter** avec email/mot de passe
3. **Vérifier** que le toggle biométrique est activé dans les paramètres
4. **Se déconnecter** (logout)
5. **Vérifier** que le bouton biométrique apparaît sur la page de login
6. **Vérifier** que le toggle biométrique est toujours activé dans les paramètres

### 2. Test de persistance après fermeture d'application
1. **Activer la biométrie** dans les paramètres
2. **Se connecter** avec email/mot de passe
3. **Fermer complètement** l'application (swipe up et fermer)
4. **Rouvrir** l'application
5. **Vérifier** que le bouton biométrique apparaît sur la page de login
6. **Vérifier** que le toggle biométrique est toujours activé dans les paramètres

### 3. Test de connexion biométrique
1. **Activer la biométrie** dans les paramètres
2. **Se connecter** avec email/mot de passe pour sauvegarder les credentials
3. **Se déconnecter**
4. **Cliquer** sur le bouton biométrique sur la page de login
5. **Authentifier** avec biométrie
6. **Vérifier** que la connexion fonctionne

### 4. Test de persistance après redémarrage du téléphone
1. **Activer la biométrie** dans les paramètres
2. **Se connecter** avec email/mot de passe
3. **Redémarrer** le téléphone
4. **Ouvrir** l'application
5. **Vérifier** que le bouton biométrique apparaît sur la page de login
6. **Vérifier** que le toggle biométrique est toujours activé dans les paramètres

## Corrections apportées

### 1. Modification des méthodes de logout
- **Fichier** : `lib/main.dart` - méthode `handleLogout()`
- **Fichier** : `lib/features/auth/modifier_mot_de_passe_screen.dart` - méthode `_logout()`  
- **Fichier** : `lib/features/auth/change_password_screen.dart` - méthode `_logout()`
- **Fichier** : `lib/features/auth/modifier_mot_de_passe_screen_new.dart` - méthode `_logout()`

### 2. Logique de préservation
```dart
// Sauvegarder les paramètres biométriques avant d'effacer
final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

await prefs.clear(); // Efface tous les tokens et infos utilisateur

// Restaurer les paramètres biométriques
if (biometricEnabled) {
  await prefs.setBool('biometric_enabled', true);
}
```

### 3. Séparation des storages
- **SharedPreferences** : Stocke l'état d'activation (`biometric_enabled`)
- **FlutterSecureStorage** : Stocke les credentials sécurisés (token, email) - non affecté par `prefs.clear()`

## Résultat attendu

✅ **L'activation biométrique persiste** après logout  
✅ **L'activation biométrique persiste** après fermeture d'application  
✅ **Les credentials biométriques restent** sauvegardés de manière sécurisée  
✅ **Le bouton biométrique apparaît** sur la page de login quand activé  
✅ **La connexion biométrique fonctionne** après logout/fermeture  

## Logs de debug

Les logs suivants devraient apparaître dans la console :
- `DEBUG LOGIN: Checking biometric status...`
- `DEBUG LOGIN: isEnabled = true` (après activation)
- `DEBUG LOGIN: hasCredentials = true` (après première connexion)
- `DEBUG LOGIN: _biometricAvailable = true` (pour afficher le bouton)
