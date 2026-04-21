package com.example.gradcheckin

import android.os.Build
import android.os.Environment
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gradcheckin/storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageRootPath" -> {
                    result.success(Environment.getExternalStorageDirectory().absolutePath)
                }
                "getAndroidSdkInt" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                else -> result.notImplemented()
            }
        }
    }
}
