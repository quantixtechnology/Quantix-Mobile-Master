plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quantix_customer_app"
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
        applicationId = "com.example.quantix_customer_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "Quantix"
    }

    flavorDimensions += "brand"

    productFlavors {
        create("arbaz") {
            dimension = "brand"
            applicationId = "com.arbazfreshmeat.app"
            manifestPlaceholders["appName"] = "Arbaz Fresh Meat"
        }
        create("freshmart") {
            dimension = "brand"
            applicationId = "com.freshmart.app"
            manifestPlaceholders["appName"] = "Fresh Mart"
        }
        create("salon") {
            dimension = "brand"
            applicationId = "com.salon.quantix.app"
            manifestPlaceholders["appName"] = "Salon App"
        }
        create("restaurant") {
            dimension = "brand"
            applicationId = "com.restaurant.quantix.app"
            manifestPlaceholders["appName"] = "Restaurant App"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
