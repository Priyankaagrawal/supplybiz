plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val firebaseConfigs = listOf("dev", "staging", "prod").map {
    file("src/$it/google-services.json")
}
if (firebaseConfigs.any { it.isFile }) {
    pluginManager.apply("com.google.gms.google-services")
    tasks.configureEach {
        if (name.startsWith("process") && name.endsWith("GoogleServices")) {
            val flavor = listOf("dev", "staging", "prod").firstOrNull {
                name.startsWith("process" + it.replaceFirstChar { char -> char.uppercase() })
            }
            if (flavor != null) {
                enabled = file("src/$flavor/google-services.json").isFile
            }
        }
    }
}

android {
    namespace = "in.supplybiz.supplybiz_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Supply Biz Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Supply Biz Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Supply Biz")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "in.supplybiz.mobile"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
