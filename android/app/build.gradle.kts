import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key (docs/yayin_rehberi.md §2). android/key.properties is git-ignored:
//   storePassword=...  keyPassword=...  keyAlias=upload  storeFile=/abs/path/upload-keystore.jks
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile") != null

// Values passed with --dart-define / --dart-define-from-file reach Gradle as a
// comma-separated list of base64 "KEY=VALUE" entries.
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.mapNotNull { runCatching { String(Base64.getDecoder().decode(it)) }.getOrNull() }
    ?.mapNotNull { e -> e.indexOf('=').takeIf { it > 0 }?.let { e.substring(0, it) to e.substring(it + 1) } }
    ?.toMap()
    ?: emptyMap()

// Google's public TEST app id is the fallback; production builds pass the real
// one via config/prod.json (ADMOB_APP_ID_ANDROID).
val admobAppId = dartDefines["ADMOB_APP_ID_ANDROID"] ?: "ca-app-pub-3940256099942544~3347511713"

android {
    namespace = "com.owlidea.harftas"
    // flutter_local_notifications 23 needs API 37 to compile against.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // VARSAYIM: store id. Cannot change after the first Play upload.
        applicationId = "com.owlidea.harftas"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml `version: name+code`.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Lets `flutter build apk --release` work locally; such a build
                // cannot be uploaded to Play. See docs/yayin_rehberi.md.
                logger.warn("WARNING: android/key.properties missing - release build signed with the DEBUG key.")
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
