package com.expensetracker.expense_tracker

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class FloatingWidgetService : Service() {

    private lateinit var windowManager: WindowManager
    private var collapsedView: View? = null
    private var expandedView: View? = null

    private var lastX = 0
    private var lastY = 0

    companion object {
        const val CHANNEL_ID = "spendwise_floating"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.expensetracker.STOP_FLOATING"
        private const val TAP_THRESHOLD = 12

        var isRunning = false
            private set
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        showCollapsed()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        removeAllViews()
    }

    private fun removeAllViews() {
        try { collapsedView?.let { windowManager.removeView(it) } } catch (_: Exception) {}
        try { expandedView?.let { windowManager.removeView(it) } } catch (_: Exception) {}
        collapsedView = null
        expandedView = null
    }

    private fun overlayType(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

    // ── Collapsed pill (draggable) ───────────────────────────────────────────

    @SuppressLint("ClickableViewAccessibility")
    private fun showCollapsed() {
        try { expandedView?.let { windowManager.removeView(it) } } catch (_: Exception) {}
        expandedView = null

        if (collapsedView != null) return

        val view = LayoutInflater.from(this).inflate(R.layout.floating_collapsed, null)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = lastX
            y = lastY
        }

        var initialTouchX = 0f
        var initialTouchY = 0f
        var initialParamX = 0
        var initialParamY = 0
        var isDragging = false

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    initialParamX = params.x
                    initialParamY = params.y
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY

                    if (!isDragging && (abs(dx) > TAP_THRESHOLD || abs(dy) > TAP_THRESHOLD)) {
                        isDragging = true
                    }

                    if (isDragging) {
                        params.x = initialParamX + dx.toInt()
                        params.y = initialParamY + dy.toInt()
                        try { windowManager.updateViewLayout(view, params) } catch (_: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        lastX = params.x
                        lastY = params.y
                        showExpanded()
                    } else {
                        lastX = params.x
                        lastY = params.y
                    }
                    true
                }
                else -> false
            }
        }

        windowManager.addView(view, params)
        collapsedView = view
    }

    // ── Expanded overlay ─────────────────────────────────────────────────────

    private fun showExpanded() {
        try { collapsedView?.let { windowManager.removeView(it) } } catch (_: Exception) {}
        collapsedView = null

        if (expandedView != null) return

        val view = LayoutInflater.from(this).inflate(R.layout.floating_expanded, null)

        view.findViewById<View>(R.id.overlay_background).setOnClickListener { collapse() }
        view.findViewById<View>(R.id.close_btn).setOnClickListener { collapse() }

        view.findViewById<View>(R.id.camera_btn).setOnClickListener {
            collapse()
            launchQuickCapture("camera")
        }

        view.findViewById<View>(R.id.mic_btn).setOnClickListener {
            collapse()
            launchQuickCapture("mic")
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_DIM_BEHIND or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            dimAmount = 0.4f
        }

        windowManager.addView(view, params)
        expandedView = view
    }

    private fun collapse() {
        try { expandedView?.let { windowManager.removeView(it) } } catch (_: Exception) {}
        expandedView = null
        showCollapsed()
    }

    // ── Launch QuickCaptureActivity ──────────────────────────────────────────

    private fun launchQuickCapture(mode: String) {
        val intent = Intent(this, QuickCaptureActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("mode", mode)
        }
        startActivity(intent)
    }

    // ── Notification (required for foreground service) ───────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "SpendWise Quick Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the floating capture button active"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, FloatingWidgetService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 1, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("SpendWise")
            .setContentText("Quick capture is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openAppPendingIntent)
            .addAction(0, "Stop", stopPendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
}
