package com.aminemtar.joy

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "joy/share").setMethodCallHandler { call, result ->
            if (call.method != "scorecard") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val bytes = call.argument<ByteArray>("image") ?: error("Missing scorecard")
                val directory = File(cacheDir, "scorecards").apply { mkdirs() }
                val file = File(directory, "joy-${System.currentTimeMillis()}.png")
                // Only temporary share images live in this directory.
                directory.listFiles()?.filter { it.lastModified() < System.currentTimeMillis() - 86400000 }?.forEach { it.delete() }
                file.writeBytes(bytes)
                val uri = FileProvider.getUriForFile(this, "$packageName.scorecards", file)
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_TEXT, call.argument<String>("text"))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(intent, "Share JOY scorecard"))
                result.success(null)
            } catch (e: Exception) { result.error("share_failed", e.localizedMessage, null) }
        }
    }
}
