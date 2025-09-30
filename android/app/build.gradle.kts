plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Configuration de la signature
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.ena_mobile_front"
    compileSdk = 36 // Mis à jour pour compatibilité image_cropper
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID pour ENA Mobile
        applicationId = "cd.ena.mobile"
        // Configuration optimisée pour Android mobile
        minSdk = 21 // Android 5.0 (API level 21) minimum pour de meilleures performances
        targetSdk = 36 // Android 16 (API level 36) pour compatibilité image_cropper
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Optimisations pour les performances mobiles
        multiDexEnabled = true
        
        // Support des architectures ARM modernes uniquement (économie d'espace)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Configuration pour la release en production
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true 
            isShrinkResources = true
        }
        debug {
            // Configuration pour le développement
            // applicationIdSuffix = ".debug" // Désactivé car Google Services n'est configuré que pour cd.ena.mobile
            isDebuggable = true
            // Désactiver les services Google en debug pour éviter les conflits
            manifestPlaceholders["useGoogleServices"] = false
        }
    }
}

flutter {
    source = "../.."
}
