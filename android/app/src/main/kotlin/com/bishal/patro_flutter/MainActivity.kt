package com.bishal.patro_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bishal.patro_flutter/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateOngoingNotification" -> {
                    PatroNotificationHelper.updateOngoingNotification(this)
                    result.success(null)
                }
                "showNormalAlert" -> {
                    PatroNotificationHelper.showNormalAlert(this)
                    result.success(null)
                }
                "cancelOngoingNotification" -> {
                    PatroNotificationHelper.cancelNotification(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
