package com.example.frontend

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "asset_loader"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadAsset" -> {
                    val filename = call.arguments as String
                    try {
                        val inputStream = assets.open(filename)
                        val bytes = inputStream.readBytes()
                        inputStream.close()
                        result.success(bytes)
                    } catch (e: Exception) {
                        result.error("ASSET_ERROR", "Failed to load asset: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}