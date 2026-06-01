package com.example.habit_up

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AlarmActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.app.alarm/bridge"
        const val EXTRA_PAYLOAD_JSON = "payload_json"
    }

    private var initialPayload: String? = null
    private var alarmChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d("AlarmDiag", "AlarmActivity: onCreate ENTERED, window==null=${window == null}, SDK_INT=${Build.VERSION.SDK_INT}")

        super.onCreate(savedInstanceState)
        Log.d("AlarmDiag", "AlarmActivity: AFTER super.onCreate(), window==null=${window == null}")

        Log.d("AlarmDiag", "AlarmActivity: BEFORE showOverLockScreen(), window==null=${window == null}")
        showOverLockScreen()
        Log.d("AlarmDiag", "AlarmActivity: AFTER showOverLockScreen(), window==null=${window == null}")

        initialPayload = intent?.getStringExtra(EXTRA_PAYLOAD_JSON)
            ?: AlarmPayloadStore.peek(applicationContext)
        Log.d("AlarmDiag", "AlarmActivity: onCreate END, window==null=${window == null}, hasPayload=${initialPayload != null}")
    }

    override fun onResume() {
        super.onResume()
        Log.d("AlarmDiag", "AlarmActivity: onResume, window==null=${window == null}")
    }

    override fun onPause() {
        super.onPause()
        Log.d("AlarmDiag", "AlarmActivity: onPause, isFinishing=$isFinishing")
    }

    override fun onDestroy() {
        Log.d("AlarmDiag", "AlarmActivity: onDestroy, isFinishing=$isFinishing")
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val newPayload = intent.getStringExtra(EXTRA_PAYLOAD_JSON)
        if (!newPayload.isNullOrBlank()) {
            initialPayload = newPayload
            // Push the new alarm payload to the Dart stream immediately so
            // NativeAlarmOverlay / NativeAlarmScreen can update without waiting
            // for a configureFlutterEngine() callback (which only fires once).
            alarmChannel?.let { channel ->
                runCatching {
                    channel.invokeMethod("onAlarmPayload", newPayload)
                }.onFailure { _ ->
                }
            }
        } else {
            initialPayload = AlarmPayloadStore.peek(applicationContext)
        }
    }

    private fun extractAlarmId(payloadJson: String): String? {
        return runCatching {
            JSONObject(payloadJson).optString("alarmId", null)?.takeIf { it.isNotBlank() }
        }.getOrNull()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // ── Push the initial alarm payload to Flutter immediately ─────────
        // This ensures that when the AlarmActivity launches (over the lock
        // screen), the Flutter engine receives the payload right away and can
        // render the full-screen alarm UI without polling or waiting.
        val payloadToDeliver = initialPayload
            ?: AlarmPayloadStore.peek(applicationContext)
        if (!payloadToDeliver.isNullOrBlank()) {
            runCatching {
                alarmChannel!!.invokeMethod("onAlarmPayload", payloadToDeliver)
            }.onFailure { _ ->
            }
        }

        alarmChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAlarmPayload" -> result.success(
                    initialPayload ?: AlarmPayloadStore.peek(applicationContext)
                )
                "dismissCurrentAlarm" -> {
                    val payload = AlarmPayloadStore.pop(applicationContext)
                    val alarmId = payload?.let { extractAlarmId(it) }
                    if (alarmId != null) {
                        AlarmForegroundService.stopAudio(applicationContext, alarmId)
                    } else {
                        AlarmForegroundService.stopAudio(applicationContext)
                    }
                    val nextPayload = AlarmPayloadStore.peek(applicationContext)
                    result.success(nextPayload)
                }
                "stopAlarmAudio" -> {
                    AlarmForegroundService.stopAudio(applicationContext)
                    result.success(null)
                }
                "snoozeAlarm" -> {
                    val payload = call.argument<String>("payload")
                    val minutes = call.argument<Int>("minutes") ?: 5
                    if (payload.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "payload is required", null)
                    } else {
                        val alarmId = extractAlarmId(payload)
                        if (alarmId != null) {
                            AlarmForegroundService.stopAudio(applicationContext, alarmId)
                        } else {
                            AlarmForegroundService.stopAudio(applicationContext)
                        }
                        AlarmPayloadStore.pop(applicationContext)
                        val trigger = System.currentTimeMillis() + minutes * 60_000L
                        AlarmScheduler.schedule(applicationContext, trigger, payload)
                        val nextPayload = AlarmPayloadStore.peek(applicationContext)
                        result.success(nextPayload)
                    }
                }
                "scheduleAlarmPayload" -> {
                    val payload = call.argument<String>("payload")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    if (payload.isNullOrBlank() || triggerAtMillis <= 0L) {
                        result.error("INVALID_ARGS", "payload and triggerAtMillis are required", null)
                    } else {
                        AlarmScheduler.schedule(applicationContext, triggerAtMillis, payload)
                        result.success(null)
                    }
                }
                "cancelAlarmPayload" -> {
                    val payload = call.argument<String>("payload")
                    if (payload.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "payload is required", null)
                    } else {
                        AlarmScheduler.cancel(applicationContext, payload)
                        result.success(null)
                    }
                }
                "saveBedtimeReminderEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("bedtime_reminder_enabled", enabled)
                        .apply()
                    result.success(null)
                }
                "saveBedtimeTime" -> {
                    val hour = call.argument<Int>("hour") ?: 21
                    val minute = call.argument<Int>("minute") ?: 0
                    getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
                        .edit()
                        .putInt("bedtime_hour", hour)
                        .putInt("bedtime_minute", minute)
                        .apply()
                    result.success(null)
                }
                "launchCalendar" -> {
                    val launch = packageManager.getLaunchIntentForPackage(packageName)
                    launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    launch?.putExtra(EXTRA_PAYLOAD_JSON, """{"type":"bedtime","route":"/calendar"}""")
                    if (launch != null) startActivity(launch)
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window?.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window?.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window?.insetsController?.let {
                it.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window?.decorView?.let { decor ->
                decor.systemUiVisibility =
                    android.view.View.SYSTEM_UI_FLAG_FULLSCREEN or
                        android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                        android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            }
        }
    }
}
