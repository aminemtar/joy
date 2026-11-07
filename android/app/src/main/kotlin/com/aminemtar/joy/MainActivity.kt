package com.aminemtar.joy

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "joy/share").setMethodCallHandler { call, result ->
            if (call.method != "text") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val text = call.argument<String>("text") ?: error("Missing share text")
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                startActivity(Intent.createChooser(intent, "Share JOY results"))
                result.success(null)
            } catch (e: Exception) {
                result.error("share_failed", e.localizedMessage, null)
            }
        }
    }
}
