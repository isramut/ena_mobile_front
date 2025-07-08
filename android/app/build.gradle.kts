plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ena_mobile_front"
    compileSdk = flutter.compileSdkVersion
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
        targetSdk = 35 // Android 15 (API level 35) pour les dernières fonctionnalités
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Optimisations pour les performances mobiles
        multiDexEnabled = true
        
        // Support des architectures ARM modernes uniquement (économie d'espace)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        release {
            // Configuration pour la release en production
            signingConfig = signingConfigs.getByName("debug") // TODO: Remplacer par la vraie signature
            // Désactivé temporairement pour éviter les problèmes de minification
            // isMinifyEnabled = true 
            // isShrinkResources = true
        }
        debug {
            // Configuration pour le développement
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
