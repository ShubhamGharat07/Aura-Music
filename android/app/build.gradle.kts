import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigning = Properties()
val signingProperties = rootProject.file("key.properties")
if (signingProperties.isFile) {
    signingProperties.inputStream().use { releaseSigning.load(it) }
}
val requireReleaseSigning = providers.gradleProperty("requireReleaseSigning").orNull == "true" ||
    providers.environmentVariable("AURA_REQUIRE_RELEASE_SIGNING").orNull == "true"

android {
    namespace = "com.example.aura_music"
    // permission_handler_android 14.x compiles against SDK 37; Flutter's
    // default (36) is below that, so pin explicitly to avoid the plugin warning.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications relies on java.time desugaring.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.auramusic.player"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingProperties.isFile) {
            create("otaRelease") {
                fun value(key: String): String = requireNotNull(releaseSigning.getProperty(key)) {
                    "Missing signing setting in android/key.properties: $key"
                }
                storeFile = rootProject.file(value("storeFile"))
                storePassword = value("storePassword")
                keyAlias = value("keyAlias")
                keyPassword = value("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Keep local release builds working while signing is configured.
            signingConfig = signingConfigs.findByName("otaRelease")
                ?: if (requireReleaseSigning) null else signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}

// Public-release tooling opts in before building a distributable APK.
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        check(!requireReleaseSigning || signingProperties.isFile) {
            "Public OTA releases require android/key.properties and a stable release keystore."
        }
    }
}
