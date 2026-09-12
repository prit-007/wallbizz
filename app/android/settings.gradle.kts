pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// Patch async_wallpaper's wallpaper.xml before any project is evaluated.
// The plugin references @mipmap/ic_launcher in its own package namespace,
// which doesn't exist during resource merging and fails on AGP 9+.
run {
    val pubCacheBase = System.getenv("PUB_CACHE") ?: (System.getProperty("user.home") + "/.pub-cache")
    val pubCache = file("$pubCacheBase/hosted/pub.dev")
    if (pubCache.isDirectory) {
        pubCache.listFiles()
            ?.filter { it.isDirectory && it.name.startsWith("async_wallpaper-") }
            ?.forEach { dir ->
                val xmlFile = java.io.File(dir, "android/src/main/res/xml/wallpaper.xml")
                if (xmlFile.exists()) {
                    val content = xmlFile.readText()
                    if (content.contains("@mipmap/ic_launcher")) {
                        xmlFile.writeText(
                            content.replace("@mipmap/ic_launcher", "@android:drawable/sym_def_app_icon"),
                        )
                    }
                }
            }
    }
}
