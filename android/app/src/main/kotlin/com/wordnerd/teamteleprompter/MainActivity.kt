package com.wordnerd.teamteleprompter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "teleprompter/export_native_ffmpeg"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "render" -> {
            val renderPlan = call.argument<Map<String, Any?>>("renderPlan")
            val commandArgs = (renderPlan?.get("ffmpegCommand") as? String)?.trim()
            if (commandArgs.isNullOrEmpty()) {
              result.success(mapOf("success" to false, "renderMode" to "native_ffmpeg_no_command"))
              return@setMethodCallHandler
            }
            try {
              val process = ProcessBuilder("sh", "-c", "ffmpeg $commandArgs")
                .redirectErrorStream(true)
                .start()
              val code = process.waitFor()
              result.success(
                mapOf(
                  "success" to (code == 0),
                  "renderMode" to if (code == 0) "native_ffmpeg_render" else "native_ffmpeg_failed"
                )
              )
            } catch (_: Exception) {
              result.success(mapOf("success" to false, "renderMode" to "native_ffmpeg_unavailable"))
            }
          }
          else -> result.notImplemented()
        }
      }
  }
}
