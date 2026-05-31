import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val socialLoginProperties = Properties()
    val socialLoginPropertiesFile = rootProject.file("social-login.properties")
    if (socialLoginPropertiesFile.exists()) {
        socialLoginPropertiesFile.inputStream().use { stream ->
            socialLoginProperties.load(stream)
        }
    }

    val keyProperties = Properties()
    val keyPropertiesFile = rootProject.file("key.properties")
    if (keyPropertiesFile.exists()) {
        keyPropertiesFile.inputStream().use { stream ->
            keyProperties.load(stream)
        }
    }
    val hasReleaseSigning = listOf(
        "storeFile",
        "storePassword",
        "keyAlias",
        "keyPassword",
    ).all { name ->
        !keyProperties.getProperty(name).isNullOrBlank()
    }

    namespace = "com.maiyard.class_finder"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.maiyard.class_finder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["kakaoScheme"] = socialLoginProperties.getProperty(
            "kakaoScheme",
            "classfinder-kakao-disabled",
        )
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Keep debug signing only for local smoke builds.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
