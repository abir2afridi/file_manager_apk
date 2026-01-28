package com.example.file_explorer_apk

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val storageChannel = "com.abir.file_manager/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageInfo" -> {
                    try {
                        val statFs = StatFs(Environment.getDataDirectory().path)
                        val totalBytes = statFs.totalBytes
                        val freeBytes = statFs.availableBytes
                        val usedBytes = totalBytes - freeBytes

                        result.success(
                            mapOf(
                                "total" to totalBytes,
                                "free" to freeBytes,
                                "used" to usedBytes
                            )
                        )
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
