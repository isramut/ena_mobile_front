# 🍎 MIGRATION iOS - GUIDE COMPLET

## ✅ DÉJÀ FAIT SUR WINDOWS :

### 1. Bundle Identifier modifié
- ✅ Changé de `com.example.enaMobileFront` vers `cd.ena.mobile`
- ✅ Mis à jour dans tous les fichiers de configuration Xcode

### 2. Template Firebase créé
- ✅ Fichier `ios/Runner/GoogleService-Info.plist` template créé
- ⚠️ DOIT être remplacé par le vrai fichier Firebase sur Mac

### 3. Script de préparation Mac
- ✅ `prepare_ios_mac.sh` créé avec toutes les étapes automatisées

### 4. Permissions iOS
- ✅ Toutes les permissions configurées dans `ios/Runner/Info.plist`
- ✅ Caméra, galerie, Face ID, internet configurés

## 🔥 À FAIRE SUR MAC :

### 1. Installation Xcode
```bash
# Installer Xcode depuis App Store
# Puis vérifier
flutter doctor
```

### 2. Firebase iOS Configuration
✅ **DÉJÀ FAIT** - GoogleService-Info.plist configuré avec vraies clés Firebase

### 3. Xcode Signing
```bash
# Ouvrir le projet
open ios/Runner.xcworkspace

# Dans Xcode:
# 1. Sélectionner "Runner" dans la barre latérale
# 2. Onglet "Signing & Capabilities"
# 3. Team: Ajouter Apple ID → isramut7@gmail.com
# 4. Vérifier Bundle Identifier: cd.ena.mobile
# 5. Cocher "Automatically manage signing"
```

### 4. Premier test
```bash
# Exécuter le script de préparation
chmod +x prepare_ios_mac.sh
./prepare_ios_mac.sh

# Puis tester
flutter run -d ios
```

## 🎯 RÉSULTAT ATTENDU :
- ✅ Compilation iOS sans erreur
- ✅ App lance sur simulateur iOS
- ✅ Firebase Analytics fonctionne
- ✅ Installation sur iPhone physique possible

## 📋 CHECKLIST FINALE :
- [ ] Xcode installé et configuré
- [ ] Vrai GoogleService-Info.plist en place
- [ ] Certificats de développement configurés
- [ ] Premier build iOS réussi
- [ ] Test sur simulateur iOS
- [ ] Test sur iPhone physique (optionnel)

## 🆘 AIDE :
Si problème, vérifier dans l'ordre :
1. `flutter doctor` (tout doit être ✅)
2. Firebase console (projet iOS ajouté)
3. Xcode signing (Team sélectionné)
4. Bundle ID cohérent partout
