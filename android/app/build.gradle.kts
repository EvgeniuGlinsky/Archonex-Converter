import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing details, kept out of the repository.
//
// `android/key.properties` points at a keystore that lives outside the project
// and holds its passwords; it is gitignored, and so is never on GitHub. CI writes
// the same file from repository secrets before building — see
// .github/workflows/release.yml.
//
// Absent, the release build falls back to the debug key. That keeps
// `flutter run --release` working on a fresh clone, and the check below is what
// makes sure a debug-signed build can never be mistaken for a publishable one.
val signingProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val hasReleaseKey = signingProperties.containsKey("storeFile")

android {
    namespace = "com.archonex.converter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.archonex.converter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(signingProperties.getProperty("storeFile"))
                storePassword = signingProperties.getProperty("storePassword")
                keyAlias = signingProperties.getProperty("keyAlias")
                keyPassword = signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Local convenience only. Anything built this way is
                // undistributable: Android will not accept an update signed by a
                // different key later, so a debug-signed release that reached
                // users could never be updated.
                logger.warn(
                    "archonex: android/key.properties is missing — signing the " +
                        "release build with the debug key. Do not distribute it."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
