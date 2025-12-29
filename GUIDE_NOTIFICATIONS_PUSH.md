# 🔔 Guide d'Utilisation - Notifications Push MyENA

## 📋 Ce qui a été implémenté

✅ **Service de Notifications Push** : Firebase Cloud Messaging intégré
✅ **Messages In-App** : Dialog centré avec design cohérent
✅ **Topics FCM** : Les users s'abonnent automatiquement à `ena_general`
✅ **Navigation depuis notifications** : Deeplinks vers les sections de l'app
✅ **Support complet** : App fermée, background, et ouverte

---

## 🚀 Démarrage Rapide

### 1. Installer les dépendances

```bash
cd "c:/Users/isram/Music/Projet MyENA/ena_mobile_front"
flutter pub get
```

### 2. Lancer l'app

```bash
# Android
flutter run

# iOS (nécessite config APNs - voir section iOS)
flutter run -d Runner
```

### 3. Premier lancement

L'app demandera automatiquement :
- **Android** : Permission "MyENA souhaite vous envoyer des notifications"
- **iOS** : Popup système pour autoriser les notifications

**⚠️ Important** : L'utilisateur DOIT accepter pour recevoir des notifications.

---

## 📱 Envoyer votre première notification

### Étape 1 : Accéder à Firebase Console

1. Ouvrir [console.firebase.google.com](https://console.firebase.google.com)
2. Sélectionner votre projet "ENA"
3. Aller dans **Messaging** (menu gauche)

### Étape 2 : Créer une campagne

1. Cliquer sur **"New Campaign"** → **"Firebase Notification messages"**
2. Remplir le formulaire :

#### **Notification**
```
Notification title : Inscriptions ouvertes
Notification text  : Les inscriptions sont ouvertes du 1er au 30 mars 2025
Notification image : (optionnel) Uploader une image
```

#### **Target (Cible)**
```
○ All users
● Topic : ena_general  ← Sélectionner cette option
```

#### **Scheduling (Planification)**
```
● Now (Envoyer maintenant)
○ Custom time (Programmer pour plus tard)
```

### Étape 3 : Configuration avancée (optionnel)

Cliquer sur **"Additional options"** :

#### **Custom data (Données personnalisées)**
```json
{
  "type": "info",
  "link": "/candidature"
}
```

**Types disponibles :**
- `info` → Icône ℹ️ bleue
- `success` → Icône ✓ verte
- `error` → Icône ✕ rouge
- `warning` → Icône ⚠️ orange
- `urgent` → Icône ⚠️ rouge

**Links disponibles :**

*Routes internes (navigation dans l'app) :*
- `/candidature` ou `/apply` → Onglet Inscription
- `/quiz` ou `/prepa` → Onglet Prépa
- `/actualites` ou `/news` → Onglet Actualités
- `/contact` → Onglet Contact
- `/profile` → Onglet Profil

*URLs externes (ouverture dans le navigateur) :*
- `https://example.com` → Ouvre dans le navigateur
- `https://myena.cd/documents` → Ouvre dans le navigateur
- Toute URL commençant par `http://` ou `https://`

### Étape 4 : Test avant envoi

1. Cliquer sur **"Send test message"**
2. Ajouter le FCM token (visible dans console de l'app)
3. Tester sur votre appareil

### Étape 5 : Envoyer

1. Cliquer sur **"Review"**
2. Vérifier le contenu
3. Cliquer sur **"Publish"**

**⏱️ Délai de réception** : 5-30 secondes

---

## 🎨 Résultats selon l'état de l'app

### **App FERMÉE** → Push système
```
┌────────────────────────────────┐
│ 🔵 MyENA              15:30    │
│ Inscriptions ouvertes           │
│ Du 1er au 30 mars 2025         │
└────────────────────────────────┘
```
Tap → App s'ouvre → Navigation selon link

### **App BACKGROUND** → Push système
```
Notification identique
```
Tap → App au premier plan → Navigation selon link

### **App OUVERTE** → Dialog centré
```
        ┌───────────────────────┐
        │                       │
        │       🔵              │
        │     [INFO]            │
        │                       │
        │  Inscriptions         │
        │  ouvertes             │
        │                       │
        │  Du 1er au 30 mars    │
        │                       │
        │ [Fermer]  [Voir]      │
        └───────────────────────┘
```

---

## 🎯 Topics FCM

### Topics auto-abonnés
- `ena_general` : Tous les users (abonné automatiquement)

### Topics optionnels (à configurer manuellement)
```dart
// Dans l'app, ajouter selon besoin
await PushNotificationService.subscribeToTopic('ena_candidats');
await PushNotificationService.subscribeToTopic('ena_etudiants');
await PushNotificationService.subscribeToTopic('ena_alertes');
```

### Envoyer à un topic spécifique
Firebase Console → Target → Topic → Choisir le topic

---

## 📊 Exemples de notifications

### 1. Annonce générale (info)
```
Title : Nouvelle session de formation
Text  : Inscrivez-vous avant le 15 février
Data  : {"type": "info", "link": "/news"}
Topic : ena_general
```

### 2. Alerte urgente
```
Title : Date limite approche
Text  : Vous avez 48h pour soumettre votre dossier
Data  : {"type": "urgent", "link": "/apply"}
Topic : ena_candidats
```

### 3. Résultat accepté
```
Title : Félicitations !
Text  : Votre candidature a été acceptée
Data  : {"type": "success", "link": "/profile"}
Topic : User-specific (via token)
```

### 4. Nouveau quiz disponible
```
Title : Quiz Droit Administratif
Text  : Testez vos connaissances maintenant
Data  : {"type": "info", "link": "/quiz"}
Topic : ena_etudiants
```

---

## 🍎 Configuration iOS (Optionnel)

### Prérequis
- **Compte Apple Developer** (99$/an)
- **Xcode** installé sur Mac

### Étapes

#### 1. Créer APNs Auth Key
1. Se connecter à [developer.apple.com](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → **Keys**
3. Cliquer sur **+** (Create a Key)
4. Nom : "ENA Push Notifications"
5. Cocher **Apple Push Notifications service (APNs)**
6. Télécharger le fichier `.p8`
7. Noter le **Key ID**

#### 2. Uploader dans Firebase
1. Firebase Console → Project Settings
2. Onglet **Cloud Messaging**
3. Section **iOS app configuration**
4. Cliquer sur **Upload** sous "APNs Authentication Key"
5. Uploader le fichier `.p8`
6. Entrer **Team ID** (depuis Apple Developer)
7. Entrer **Key ID**

#### 3. Activer dans Xcode
1. Ouvrir `ios/Runner.xcworkspace` dans Xcode
2. Target "Runner" → **Signing & Capabilities**
3. Cliquer sur **+ Capability**
4. Ajouter **Push Notifications**
5. Ajouter **Background Modes** (déjà fait dans Info.plist)

### Sans compte Apple Developer
**Limitations** :
- ❌ Push notifications iOS ne fonctionneront PAS
- ✅ Android fonctionne parfaitement (gratuit)
- ✅ Vous pouvez tester sur Android uniquement

---

## 🔧 Dépannage

### "Permission refusée" (Android 13+)
**Problème** : L'utilisateur a refusé les notifications

**Solution** :
1. Paramètres Android → Apps → MyENA → Notifications
2. Activer "Toutes les notifications"

### "Aucune notification reçue"
**Vérifications** :
1. ✅ L'app a demandé la permission ?
2. ✅ La permission a été acceptée ?
3. ✅ Le topic est correct (`ena_general`) ?
4. ✅ Internet est activé ?
5. ✅ Google Play Services est installé (Android) ?

**Debug** :
```
1. Ouvrir l'app
2. Vérifier console : "✅ User granted permission"
3. Vérifier console : "🔑 FCM Token: ..."
4. Vérifier console : "✅ Subscribed to topic: ena_general"
```

### FCM Token introuvable
**Dans l'app, après ouverture, la console affiche** :
```
🚀 Initializing Push Notification Service...
✅ User granted permission for notifications
🔑 FCM Token: cXo8... (long string)
✅ Subscribed to topic: ena_general
```

**Copier le token** pour test Firebase Console

### iOS : "No registration tokens found"
**Cause** : APNs non configuré

**Solutions** :
1. Configurer APNs (voir section iOS)
2. OU tester uniquement sur Android

---

## 📈 Analytics

### Événements automatiques trackés
- `push_notifications_enabled` : User a activé les notifications
- `notification_received_foreground` : Notification reçue app ouverte
- `notification_tapped` : User a tapé sur notification
- `subscribed_to_topic` : Abonnement à un topic

### Voir les statistiques
Firebase Console → Analytics → Events

---

## 🎓 Bonnes pratiques

### ✅ À faire
- Tester sur un vrai appareil (pas émulateur)
- Utiliser des titres courts (<50 caractères)
- Messages clairs et concis (<150 caractères)
- Ajouter toujours le champ `type` dans data
- Programmer les envois aux heures appropriées

### ❌ À éviter
- Envoyer trop de notifications (spam)
- Titres trop longs (tronqués sur mobile)
- Oublier le champ `link` si action nécessaire
- Envoyer sans tester d'abord

---

## 📞 Support

En cas de problème :
1. Vérifier console de l'app (erreurs affichées)
2. Vérifier Firebase Console → Cloud Messaging → Reports
3. Tester avec "Send test message" d'abord

---

## ✅ Checklist de vérification

Avant d'envoyer une notification importante :

- [ ] Titre et message bien rédigés
- [ ] Topic correct sélectionné
- [ ] Type défini dans custom data
- [ ] Link défini si action requise
- [ ] Test envoyé et validé
- [ ] Heure d'envoi appropriée
- [ ] Pas d'envoi en doublon

**Tout est prêt ! Vos notifications push sont opérationnelles** 🚀
