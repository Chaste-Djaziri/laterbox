package com.example.laterbox

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pendingShares by lazy { PendingShareQueue(applicationContext) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enqueueShareIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeShares" -> {
                    result.success(pendingShares.consumeAll())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        enqueueShareIntent(intent)
    }

    private fun enqueueShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("text/") != true) return

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: return

        pendingShares.enqueue(text)
    }

    companion object {
        private const val CHANNEL = "laterbox/android_share"
    }
}
