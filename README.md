# 📱 ENA Mobile - Application Mobile Officielle

Application mobile Flutter pour l'École Nationale d'Administration de la République Démocratique du Congo.

## 🎯 **Fonctionnalités**

### 🔐 **Authentification & Sécurité**
- Connexion sécurisée avec authentification biométrique (Face ID/Touch ID)
- Système de récupération de mot de passe
- Stockage sécurisé des données utilisateur

### 📝 **Candidature**
- Formulaire de candidature multi-étapes
- Upload de documents (PDF, DOCX, images)
- Sauvegarde automatique
- Validation en temps réel

### 🎓 **Préparation ENA**
- Quiz interactifs
- Contenu de préparation
- Suivi des progrès

### 💬 **Assistant Intelligent**
- Chatbot ENA Mwinda avec IA
- Réponses instantanées
- Support candidats

### 📊 **Analytics & Suivi**
- Firebase Analytics intégré
- Suivi des événements utilisateur
- Statistiques d'utilisation

## 🛠️ **Technologies**

- **Framework**: Flutter 3.32.5
- **Backend**: API REST personnalisée
- **Base de données**: Firebase
- **Authentification**: Biométrique + JWT
- **Analytics**: Firebase Analytics
- **Caching**: Stratégie de cache intelligent

## 📱 **Plateformes Supportées**

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)

## 🚀 **Installation & Configuration**

### **Prérequis**
- Flutter SDK 3.32.5+
- Android Studio / Xcode
- Firebase project configuré

### **Installation**
```bash
# Cloner le repository
git clone https://github.com/isramut/ena_mobile_front.git
cd ena_mobile_front

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### **Configuration Firebase**
1. Ajouter `google-services.json` dans `android/app/`
2. Ajouter `GoogleService-Info.plist` dans `ios/Runner/`

### **Configuration iOS (Mac uniquement)**
```bash
# Exécuter le script de préparation
chmod +x prepare_ios_mac.sh
./prepare_ios_mac.sh

# Ouvrir Xcode et configurer signing
open ios/Runner.xcworkspace
```

## 📂 **Structure du Projet**

```
lib/
├── common/          # Composants partagés
├── config/          # Configuration
├── features/        # Fonctionnalités par module
│   ├── auth/        # Authentification
│   ├── apply/       # Candidature
│   ├── prepa/       # Préparation ENA
│   └── chat/        # Assistant IA
├── models/          # Modèles de données
├── services/        # Services API
├── utils/           # Utilitaires
└── widgets/         # Composants UI réutilisables
```

## 🔧 **Configuration Environnement**

Créer un fichier `.env` à la racine :
```env
API_BASE_URL=https://votre-api.com
GEMINI_API_KEY=votre_cle_gemini
```

## 📈 **Analytics & Monitoring**

- **Firebase Analytics**: Suivi des événements utilisateur
- **Crash Reporting**: Détection automatique des erreurs
- **Performance Monitoring**: Optimisation des performances

## 🏗️ **Architecture**

- **Pattern**: Clean Architecture + BLoC
- **State Management**: Provider
- **Navigation**: Flutter Router
- **Caching**: Multi-layer cache strategy
- **Security**: End-to-end encryption

## 🔒 **Sécurité**

- Authentification biométrique
- Chiffrement des données sensibles
- Validation côté client et serveur
- Protection contre les attaques CSRF

## 🌐 **API Integration**

L'application s'intègre avec :
- API d'authentification ENA
- API de candidature
- API de gestion des quiz
- Services Firebase

## 📱 **Bundle Identifiers**

- **Android**: `cd.ena.mobile`
- **iOS**: `cd.ena.mobile`

## 👥 **Équipe de Développement**

- **Développeur Principal**: @isramut
- **Framework**: Flutter
- **Plateforme**: Cross-platform (Android/iOS)

## 📄 **Licence**

© 2025 École Nationale d'Administration - République Démocratique du Congo
Tous droits réservés.

## 📞 **Support**

Pour toute question ou assistance :
- Email: support@ena.cd
- Site web: https://ena.cd

---

**🇨🇩 Développé avec ❤️ pour l'ENA - République Démocratique du Congo**
