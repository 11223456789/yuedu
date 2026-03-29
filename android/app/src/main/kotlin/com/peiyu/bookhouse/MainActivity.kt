package com.peiyu.bookhouse

import android.content.Intent
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val VOLUME_KEY_CHANNEL = "com.peiyu.bookhouse/volume_key"
    private val INTENT_CHANNEL = "com.peiyu.bookhouse/intent"
    private var volumeKeyEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 音量键事件通道（阅读翻页）
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VOLUME_KEY_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeKeyEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    volumeKeyEventSink = null
                }
            })

        // Intent 处理通道（文件关联、URL Scheme、文本分享）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialIntent" -> {
                        result.success(getIntentData(intent))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                volumeKeyEventSink?.success("volume_up")
                true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                volumeKeyEventSink?.success("volume_down")
                true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // 通知 Flutter 新 Intent
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, INTENT_CHANNEL)
                .invokeMethod("onNewIntent", getIntentData(intent))
        }
    }

    private fun getIntentData(intent: Intent?): Map<String, String?> {
        if (intent == null) return emptyMap()
        return mapOf(
            "action" to intent.action,
            "data" to intent.dataString,
            "type" to intent.type,
            "text" to intent.getStringExtra(Intent.EXTRA_TEXT),
            "processText" to intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        )
    }
}
