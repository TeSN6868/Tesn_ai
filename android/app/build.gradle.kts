import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()

    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    namespace = "com.bhre.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bhre.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.create("release") {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                    storeType = keystoreProperties["storeType"] as String
                }
            } else {
                signingConfigs.getByName("debug")
            }
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


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
