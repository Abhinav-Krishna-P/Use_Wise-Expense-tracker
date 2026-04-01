package com.expensetracker.expense_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class QuickCaptureActivity : FlutterActivity() {

    override fun getDartEntrypointFunctionName(): String = "quickCaptureMain"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mode = intent.getStringExtra("mode") ?: ""

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.expensetracker/quickcapture")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchMode" -> result.success(mode)
                    else -> result.notImplemented()
                }
            }
    }
}
