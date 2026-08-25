import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Carregar propriedades do keystore
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "br.com.aranetprovedor.client"
    compileSdk = flutter.compileSdkVersion
    // Segue a versão do NDK mantida pelo próprio Flutter SDK pelo mesmo
    // motivo do targetSdk: evita ficar presa a um número desatualizado.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.aranetprovedor.client"
        minSdk = flutter.minSdkVersion
        // Segue o valor mantido pelo próprio Flutter SDK em vez de fixar um
        // número, para que o app sempre segmente o nível de API mais recente
        // suportado (exigência do Google Play) sem precisar de intervenção
        // manual a cada novo release do Android.
        targetSdk = flutter.targetSdkVersion
        versionCode = 6
        versionName = "1.0.2"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            val keyAlias = keystoreProperties["keyAlias"] as? String
            val keyPassword = keystoreProperties["keyPassword"] as? String
            val storeFile = keystoreProperties["storeFile"] as? String
            val storePassword = keystoreProperties["storePassword"] as? String

            if (keyAlias != null && keyPassword != null && storeFile != null && storePassword != null) {
                create("release") {
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                    this.storeFile = file(storeFile)
                    this.storePassword = storePassword
                }
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists() && signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
