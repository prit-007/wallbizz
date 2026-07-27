package com.wallbizz.app

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wallbizz.app/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToGallery" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        val subDir = call.argument<String>("subDir") ?: "VivekWallpapers"

                        if (sourcePath == null || fileName == null) {
                            result.error("INVALID_ARGS", "sourcePath and fileName required", null)
                            return@setMethodCallHandler
                        }

                        val success = saveToGallery(sourcePath, fileName, subDir)
                        result.success(success)
                    }
                    "scanMedia" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            result.error("INVALID_ARGS", "filePath required", null)
                            return@setMethodCallHandler
                        }
                        scanMedia(filePath)
                        result.success(true)
                    }
                    "getGalleryPath" -> {
                        val subDir = call.argument<String>("subDir") ?: "VivekWallpapers"
                        val path = getGalleryPath(subDir)
                        result.success(path)
                    }
                    "requestManageStorage" -> {
                        // Permission request is handled in Flutter via permission_handler
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getGalleryPath(subDir: String): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            File(picturesDir, subDir).absolutePath
        } else {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            File(picturesDir, subDir).absolutePath
        }
    }

    private fun saveToGallery(sourcePath: String, fileName: String, subDir: String): Boolean {
        return try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) return false

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ : Use MediaStore API
                val resolver = contentResolver
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$subDir")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                val uri = resolver.insert(collection, contentValues)

                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { outputStream ->
                        FileInputStream(sourceFile).use { inputStream ->
                            inputStream.copyTo(outputStream)
                        }
                    }

                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                    true
                } else {
                    false
                }
            } else {
                // Android 9 and below : Direct file copy
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val destDir = File(picturesDir, subDir)
                if (!destDir.exists()) destDir.mkdirs()

                val destFile = File(destDir, fileName)
                sourceFile.copyTo(destFile, overwrite = true)

                // Trigger media scan
                MediaScannerConnection.scanFile(this, arrayOf(destFile.absolutePath), null, null)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun scanMedia(filePath: String) {
        MediaScannerConnection.scanFile(this, arrayOf(filePath), null, null)
    }
}
