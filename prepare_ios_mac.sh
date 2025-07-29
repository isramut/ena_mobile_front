#!/bin/bash

# 🍎 SCRIPT DE PRÉPARATION iOS SUR MAC
# Exécuter ce script une fois sur Mac avec Xcode installé

echo "🍎 Préparation du projet ENA Mobile pour iOS..."

# 1. Vérifier que nous sommes sur Mac
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Ce script doit être exécuté sur macOS"
    exit 1
fi

# 2. Vérifier Flutter
echo "📱 Vérification Flutter..."
flutter doctor

# 3. Vérifier Xcode
echo "🔧 Vérification Xcode..."
xcode-select --print-path

# 4. Installer les dépendances iOS
echo "📦 Installation des pods iOS..."
cd ios
pod install --repo-update
cd ..

# 5. Instructions Firebase
echo ""
echo "🔥 ÉTAPES FIREBASE À COMPLÉTER :"
echo "1. Aller sur https://console.firebase.google.com"
echo "2. Sélectionner le projet ENA"
echo "3. Ajouter une application iOS"
echo "4. Bundle ID: cd.ena.mobile"
echo "5. Télécharger GoogleService-Info.plist"
echo "6. Remplacer ios/Runner/GoogleService-Info.plist"
echo ""

# 6. Instructions Xcode
echo "🔧 ÉTAPES XCODE À COMPLÉTER :"
echo "1. Ouvrir: open ios/Runner.xcworkspace"
echo "2. Sélectionner Runner dans la barre latérale"
echo "3. Onglet 'Signing & Capabilities'"
echo "4. Team: Sélectionner votre Apple ID"
echo "5. Vérifier Bundle Identifier: cd.ena.mobile"
echo ""

# 7. Test de compilation
echo "🧪 Test de compilation iOS..."
flutter clean
flutter pub get
flutter build ios --debug --no-codesign

echo "✅ Préparation terminée ! Suivez les instructions ci-dessus."
