plugins {
    id("com.android.application")
    kotlin("android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.swiftwash_mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.swiftwash_mobile"
        minSdkVersion(flutter.minSdkVersion) // A common minimum SDK version
        targetSdk = 36 // Match compileSdk
        versionCode = 1
        versionName = "1.0"
    }

        buildTypes {
            release {
                // signingConfig = signingConfigs.getByName("debug")  // Commented out for debug builds
                proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            }
        }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.razorpay:checkout:1.6.36")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
