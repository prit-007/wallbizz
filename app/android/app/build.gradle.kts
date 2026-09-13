plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Base64
import java.util.Properties

android {
    namespace = "com.wallbizz.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wallbizz.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // CI: GitHub Secrets > Local: key.properties
            val keystoreB64 = System.getenv("KEYSTORE_BASE64")
            if (!keystoreB64.isNullOrEmpty()) {
                // CI path — decode base64 keystore from secret
                val keystoreBytes = Base64.getDecoder().decode(keystoreB64)
                val keystoreFile = File(rootProject.buildDir, "keystore/wallbizz.keystore")
                keystoreFile.parentFile.mkdirs()
                keystoreFile.writeBytes(keystoreBytes)
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: "wallbizz"
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            } else {
                // Local dev path — read from key.properties
                val props = Properties()
                val propsFile = rootProject.file("key.properties")
                if (propsFile.exists()) {
                    props.load(propsFile.inputStream())
                    storeFile = file(props["storeFile"] as String)
                    storePassword = props["storePassword"] as String
                    keyAlias = props["keyAlias"] as String
                    keyPassword = props["keyPassword"] as String
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
