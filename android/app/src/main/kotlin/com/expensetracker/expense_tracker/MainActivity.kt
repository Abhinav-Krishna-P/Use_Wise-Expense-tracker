package com.expensetracker.expense_tracker

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.expensetracker/widget"
    private val SHARE_CHANNEL  = "com.expensetracker/share"
    private val OVERLAY_PERMISSION_REQUEST = 5001

    private var pendingResult: MethodChannel.Result? = null
    private var shareChannel: MethodChannel? = null

    // Holds a share payload that arrived before Flutter was ready
    private var pendingShareBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Widget channel ──────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFloatingWidget" -> {
                        if (canDrawOverlays()) {
                            startFloatingService()
                            result.success(true)
                        } else {
                            pendingResult = result
                            requestOverlayPermission()
                        }
                    }
                    "stopFloatingWidget" -> {
                        stopFloatingService()
                        result.success(true)
                    }
                    "isFloatingWidgetRunning" -> {
                        result.success(FloatingWidgetService.isRunning)
                    }
                    "hasOverlayPermission" -> {
                        result.success(canDrawOverlays())
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Share channel ───────────────────────────────────────────────────
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        shareChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShare" -> {
                    // Flutter calls this on startup to retrieve any pending share
                    val bytes = pendingShareBytes
                    pendingShareBytes = null
                    if (bytes != null) {
                        result.success(bytes)
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // If a share intent arrived before Flutter engine was ready, push it now
        pendingShareBytes?.let { bytes ->
            shareChannel?.invokeMethod("onShareReceived", bytes)
            pendingShareBytes = null
        }
    }

    // Called when the activity is created fresh (app was not running)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleShareIntent(intent)
    }

    // Called when the app is already running (singleTop) and gets a new intent
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        val mimeType = intent.type ?: return
        if (!mimeType.startsWith("image/")) return

        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java) ?: return
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM) ?: return
        }

        val bytes = readUriBytesOrNull(uri) ?: return

        val channel = shareChannel
        if (channel != null) {
            // Flutter engine is ready — send immediately
            channel.invokeMethod("onShareReceived", bytes)
        } else {
            // Flutter not ready yet — store and deliver from configureFlutterEngine / getPendingShare
            pendingShareBytes = bytes
        }
    }

    private fun readUriBytesOrNull(uri: Uri): ByteArray? = try {
        contentResolver.openInputStream(uri)?.use { it.readBytes() }
    } catch (e: Exception) {
        null
    }

    // ── Overlay helpers ─────────────────────────────────────────────────────

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            @Suppress("DEPRECATION")
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == OVERLAY_PERMISSION_REQUEST) {
            if (canDrawOverlays()) {
                startFloatingService()
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun startFloatingService() {
        val intent = Intent(this, FloatingWidgetService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopFloatingService() {
        stopService(Intent(this, FloatingWidgetService::class.java))
    }
}
