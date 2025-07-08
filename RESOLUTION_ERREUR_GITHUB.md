# 🔧 RÉSOLUTION ERREUR REPOSITORY GITHUB

## ❌ **Erreurs communes :**
- "Repository not found" 
- "Permission denied"
- "Authentication failed"

## 🔍 **DIAGNOSTIC RAPIDE**

### 1. Vérifier le remote configuré
```bash
git remote -v
# Doit afficher : origin https://github.com/isramut/ENA-MOBILE.git
```

### 2. Vérifier l'authentification GitHub
```bash
# Test de connexion
ssh -T git@github.com

# Ou pour HTTPS, configurer les credentials
git config user.name "Votre Nom"
git config user.email "votre.email@example.com"
```

## 💡 **SOLUTIONS PAR PROBLÈME**

### **Problème 1 : Repository n'existe pas**
```bash
# 1. Aller sur https://github.com/isramut
# 2. Vérifier que le repository "ENA-MOBILE" existe
# 3. S'il n'existe pas, le créer :
#    - New repository
#    - Nom: ENA-MOBILE  
#    - Public/Private selon préférence
#    - NE PAS initialiser avec README
```

### **Problème 2 : Mauvais nom de repository**
```bash
# Changer le remote vers le bon repository
git remote set-url origin https://github.com/isramut/NOUVEAU-NOM-REPO.git

# Vérifier
git remote -v
```

### **Problème 3 : Problème d'authentification HTTPS**
```bash
# Option A : Utiliser token personnel
# 1. GitHub → Settings → Developer settings → Personal access tokens
# 2. Generate new token (classic)
# 3. Sélectionner scopes: repo, workflow
# 4. Copier le token

# 5. Utiliser le token pour push
git push https://YOUR_TOKEN@github.com/isramut/ENA-MOBILE.git master
```

### **Problème 4 : Utiliser SSH (plus sécurisé)**
```bash
# 1. Générer clé SSH (si pas déjà fait)
ssh-keygen -t ed25519 -C "votre.email@example.com"

# 2. Ajouter la clé à l'agent SSH
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Copier la clé publique
cat ~/.ssh/id_ed25519.pub

# 4. Ajouter sur GitHub : Settings → SSH and GPG keys → New SSH key

# 5. Changer remote en SSH
git remote set-url origin git@github.com:isramut/ENA-MOBILE.git

# 6. Test connexion
ssh -T git@github.com

# 7. Push
git push -u origin master
```

## 🚀 **COMMANDES POUR VOTRE CAS SPÉCIFIQUE**

### Étape 1 : Vérifier l'état actuel
```powershell
# Dans PowerShell
git status
git remote -v
git log --oneline -3
```

### Étape 2 : Solutions selon votre situation

#### **Si le repository ENA-MOBILE existe sur GitHub :**
```powershell
# Essayer avec authentification explicite
git push -u origin master --verbose

# Si erreur d'auth, utiliser token :
git remote set-url origin https://YOUR_TOKEN@github.com/isramut/ENA-MOBILE.git
git push -u origin master
```

#### **Si vous voulez créer un nouveau repository :**
```powershell
# 1. Créer sur GitHub avec nom: ena_mobile_front
# 2. Changer remote
git remote set-url origin https://github.com/isramut/ena_mobile_front.git
# 3. Push
git push -u origin master
```

#### **Si vous voulez utiliser le repository existant ENA-MOBILE :**
```powershell
# Push directement (si auth ok)
git push -u origin master
```

## 🔑 **AUTHENTIFICATION GITHUB**

### Méthode recommandée : Personal Access Token
```
1. GitHub.com → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. Generate new token
4. Name: "ENA Mobile Development"
5. Expiration: 90 days (ou plus)
6. Scopes: ✅ repo, ✅ workflow
7. Generate token
8. COPIER LE TOKEN (il ne sera plus affiché)
```

### Utiliser le token :
```bash
# Remplacer YOUR_TOKEN par votre vrai token
git remote set-url origin https://YOUR_TOKEN@github.com/isramut/ENA-MOBILE.git
git push -u origin master
```

## ⚡ **SOLUTION RAPIDE**

Si vous voulez juste que ça marche maintenant :

```powershell
# 1. Créer un Personal Access Token sur GitHub
# 2. Remplacer YOUR_TOKEN dans la commande :
git remote set-url origin https://YOUR_TOKEN@github.com/isramut/ENA-MOBILE.git

# 3. Push
git push -u origin master
```

## 📞 **Si rien ne marche :**

1. **Vérifier que le repository https://github.com/isramut/ENA-MOBILE existe**
2. **Créer un nouveau repository** si nécessaire
3. **Utiliser un Personal Access Token** pour l'authentification
4. **Essayer SSH** si HTTPS pose problème

---
**💡 Conseil :** Utilisez toujours des Personal Access Tokens pour HTTPS, c'est plus sécurisé que le mot de passe.
