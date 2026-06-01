package com.example.habit_up
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    companion object {
        private const val REQUEST_POST_NOTIFICATIONS = 9001
        private const val REQUEST_READ_MEDIA_AUDIO = 9002

        // Method channel name (must match Dart side)
        private const val CHANNEL = "com.example.habit_up/permissions"
        private const val ALARM_BRIDGE_CHANNEL = "com.app.alarm/bridge"

        // ── Notification Channel IDs (must match Dart side exactly) ──────
        const val CHANNEL_TASK_ALARMS = "task_reminders"
        const val CHANNEL_BEDTIME = "bedtime_reminder"
        const val CHANNEL_GENERAL = "general_reminders"
        const val CHANNEL_FULL_SCREEN_ALARM = "full_screen_alarm"

        // ── SharedPreferences keys for alarm settings ───────────────────
        private const val PREFS_NAME = "alarm_settings"
        private const val KEY_FULLSCREEN_ENABLED = "fullscreen_enabled"
        private const val KEY_VIBRATION_ENABLED = "vibration_enabled"
        private const val KEY_ALARM_SOUND_ENABLED = "alarm_sound_enabled"
        private const val KEY_SNOOZE_ENABLED = "snooze_enabled"
        private const val KEY_CUSTOM_SOUND_URI = "custom_sound_uri"
        private const val KEY_BEDTIME_HOUR = "bedtime_hour"
        private const val KEY_BEDTIME_MINUTE = "bedtime_minute"
        private const val DEFAULT_BEDTIME_HOUR = 21
        private const val DEFAULT_BEDTIME_MINUTE = 0

        // ── Public accessors for other classes (e.g. AlarmReceiver) ──────
        fun getCustomSoundUri(context: Context): String? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val uri = prefs.getString(KEY_CUSTOM_SOUND_URI, null)
            return uri?.takeIf { it.isNotBlank() }
        }

        fun getBedtimeHour(context: Context): Int {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getInt(KEY_BEDTIME_HOUR, DEFAULT_BEDTIME_HOUR)
        }

        fun getBedtimeMinute(context: Context): Int {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return prefs.getInt(KEY_BEDTIME_MINUTE, DEFAULT_BEDTIME_MINUTE)
        }
    }

    private var alarmBridgeChannel: MethodChannel? = null
    private var coldStartPayload: String? = null
    private var pendingPostNotificationResult: MethodChannel.Result? = null
    private var pendingAudioPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── Force activity to show over the lock screen and turn the screen on ──
        // This ensures the full-screen alarm launches automatically without requiring
        // a banner notification tap, even when the device is locked/screen is off.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        // Capture the alarm payload on cold-start (e.g. app was killed and launched
        // from a notification tap).  The payload is pushed to the Dart stream once
        // the method channel is available in configureFlutterEngine().
        coldStartPayload = intent?.getStringExtra(AlarmActivity.EXTRA_PAYLOAD_JSON)
            ?: AlarmPayloadStore.peek(applicationContext)

        createNotificationChannels()
        logPermissionStatus()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val newPayload = intent.getStringExtra(AlarmActivity.EXTRA_PAYLOAD_JSON)
        if (!newPayload.isNullOrBlank()) {
            alarmBridgeChannel?.let { channel ->
                runCatching {
                    channel.invokeMethod("onAlarmPayload", newPayload)
                }.onFailure { _ ->
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupMethodChannel(flutterEngine)
        setupAlarmBridge(flutterEngine)
    }

    private fun setupAlarmBridge(flutterEngine: FlutterEngine) {
        alarmBridgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_BRIDGE_CHANNEL)
        alarmBridgeChannel!!.setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkExactAlarmPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            alarmManager.canScheduleExactAlarms()
                        } else {
                            true
                        }
                        result.success(granted)
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.fromParts("package", packageName, null)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "checkFullScreenIntentPermission" -> {
                        val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            manager.canUseFullScreenIntent()
                        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            checkSelfPermission(android.Manifest.permission.USE_FULL_SCREEN_INTENT) ==
                                PackageManager.PERMISSION_GRANTED
                        } else {
                            true
                        }
                        result.success(granted)
                    }
                    "openFullScreenIntentSettings" -> {
                        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                                data = Uri.fromParts("package", packageName, null)
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        } else {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "getInitialAlarmPayload" -> {
                        val payload = coldStartPayload
                            ?: intent?.getStringExtra(AlarmActivity.EXTRA_PAYLOAD_JSON)
                            ?: AlarmPayloadStore.peek(applicationContext)
                        result.success(payload)
                    }
                    "dismissCurrentAlarm" -> {
                        val payload = AlarmPayloadStore.pop(applicationContext)
                        val alarmId = payload?.let { extractAlarmId(it) }
                        if (alarmId != null) {
                            AlarmForegroundService.stopAudio(applicationContext, alarmId)
                        } else {
                            AlarmForegroundService.stopAudio(applicationContext)
                        }
                        result.success(AlarmPayloadStore.peek(applicationContext))
                    }
                    "stopAlarmAudio" -> {
                        AlarmForegroundService.stopAudio(applicationContext)
                        result.success(null)
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
                        val hour = call.argument<Int>("hour") ?: DEFAULT_BEDTIME_HOUR
                        val minute = call.argument<Int>("minute") ?: DEFAULT_BEDTIME_MINUTE
                        getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
                            .edit()
                            .putInt(KEY_BEDTIME_HOUR, hour)
                            .putInt(KEY_BEDTIME_MINUTE, minute)
                            .apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Push cold-start payload to Dart stream ───────────────────────
        // If this activity was cold-started from a notification tap, the payload
        // was captured in onCreate() but couldn't be delivered because the method
        // channel didn't exist yet. Now that the channel is live, push it.
        val payloadToDeliver = coldStartPayload
            ?: intent?.getStringExtra(AlarmActivity.EXTRA_PAYLOAD_JSON)
            ?: AlarmPayloadStore.peek(applicationContext)
        if (!payloadToDeliver.isNullOrBlank()) {
            runCatching {
                alarmBridgeChannel!!.invokeMethod("onAlarmPayload", payloadToDeliver)
            }.onFailure { _ ->
            }
            // Clear so subsequent getInitialAlarmPayload calls still work via
            // coldStartPayload, but we don't re-push on configuration changes.
            coldStartPayload = null
        }
    }

    /**
     * Registers the MethodChannel for permission checks, settings redirection,
     * alarm scheduling via Android's AlarmManager, and alarm settings persistence.
     *
     * Available methods:
     *   - getAndroidSdkVersion      → Int (returns Build.VERSION.SDK_INT)
     *   - checkPostNotifications    → Boolean (Android 13+)
     *   - checkExactAlarm           → Boolean (Android 12+)
     *   - checkFullScreenIntent     → Boolean (Android 12+)
     *   - openAppSettings           → null
     *   - openNotificationSettings  → null
     *   - openExactAlarmSettings    → null
     *   - scheduleAlarm             → null (schedules via AlarmManager)
     *   - cancelAlarm               → null (cancels a scheduled alarm)
     *   - saveAlarmSettings         → null (saves alarm settings to SharedPreferences)
     *   - getAlarmSettings          → Map<String, Boolean> (retrieves alarm settings)
     */
    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "checkPostNotifications" -> {
                    val granted = isPostNotificationsGranted()
                    result.success(granted)
                }
                "checkExactAlarm" -> {
                    val granted = isExactAlarmGranted()
                    result.success(granted)
                }
                "checkFullScreenIntent" -> {
                    val granted = isFullScreenIntentAllowed()
                    result.success(granted)
                }
                "requestPostNotifications" -> {
                    requestPostNotifications(result)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "openExactAlarmSettings" -> {
                    openExactAlarmSettings()
                    result.success(null)
                }
                "openFullScreenIntentSettings" -> {
                    openFullScreenIntentSettings()
                    result.success(null)
                }
                // ── AlarmManager scheduling (unified path) ────────────────
                // Builds a structured JSON payload and routes through
                // AlarmScheduler.schedule(), which registers with AlarmManager
                // AND persists to AlarmPayloadStore so alarms survive reboot.
                "scheduleAlarm" -> {
                    val taskId = call.argument<String>("taskId")
                    val taskTitle = call.argument<String>("taskTitle")
                    val taskMessage = call.argument<String>("taskMessage")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L

                    if (taskId == null || triggerAtMillis == 0L) {
                        result.error("INVALID_ARGS", "taskId and triggerAtMillis required", null)
                        return@setMethodCallHandler
                    }

                    val payload = JSONObject()
                        .put("type", "task")
                        .put("alarmId", taskId)
                        .put("taskId", taskId)
                        .put("taskName", taskTitle ?: "Task alarm")
                        .put("description", taskMessage ?: "")
                        .toString()

                    AlarmScheduler.schedule(applicationContext, triggerAtMillis, payload)
                    result.success(null)
                }
                "cancelAlarm" -> {
                    val taskId = call.argument<String>("taskId")
                    if (taskId == null) {
                        result.error("INVALID_ARGS", "taskId required", null)
                        return@setMethodCallHandler
                    }
                    val payload = JSONObject()
                        .put("alarmId", taskId)
                        .put("taskId", taskId)
                        .toString()
                    AlarmScheduler.cancel(applicationContext, payload)
                    result.success(null)
                }
                // ── Alarm Settings Persistence ────────────────────────────
                // Save alarm settings to SharedPreferences for use by native code
                "saveAlarmSettings" -> {
                    val fullscreenEnabled = call.argument<Boolean>("fullscreenEnabled") ?: true
                    val vibrationEnabled = call.argument<Boolean>("vibrationEnabled") ?: true
                    val alarmSoundEnabled = call.argument<Boolean>("alarmSoundEnabled") ?: true
                    val snoozeEnabled = call.argument<Boolean>("snoozeEnabled") ?: true

                    saveAlarmSettings(fullscreenEnabled, vibrationEnabled, alarmSoundEnabled, snoozeEnabled)
                    result.success(null)
                }
                "getAlarmSettings" -> {
                    val settings = getAlarmSettings()
                    result.success(settings)
                }
                "checkAudioPermission" -> {
                    val granted = isReadMediaAudioGranted()
                    result.success(granted)
                }
                "requestAudioPermission" -> {
                    requestReadMediaAudio(result)
                }
                "openAudioPermissionSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                "checkBatteryOptimization" -> {
                    val granted = isBatteryOptimizationDisabled()
                    result.success(granted)
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                "getCustomSoundUri" -> {
                    val uri = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        .getString(KEY_CUSTOM_SOUND_URI, null)
                    result.success(uri)
                }
                "saveCustomSoundUri" -> {
                    val uri = call.argument<String>("uri")
                    getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        .edit()
                        .putString(KEY_CUSTOM_SOUND_URI, uri)
                        .apply()
                    result.success(null)
                }
                "getLastCompletedTaskId" -> {
                    val prefs = getSharedPreferences("task_completion", Context.MODE_PRIVATE)
                    val taskId = prefs.getString("last_completed_task_id", null)
                    val timestamp = prefs.getLong("completion_timestamp", 0)
                    val completionData = mapOf(
                        "taskId" to taskId,
                        "timestamp" to timestamp
                    )
                    result.success(completionData)
                    // Clear after reading
                    prefs.edit().remove("last_completed_task_id").remove("completion_timestamp").apply()
                }
                else -> result.notImplemented()
            }
        }
    }

    // ---------------------------------------------------------------------------
    // Permission check methods
    // ---------------------------------------------------------------------------

    /**
     * Check if READ_MEDIA_AUDIO is granted.
     * On Android 13+ (API 33), this is a runtime permission required to access
     * user-selected audio files for custom alarm sounds.
     * On older versions, the permission is implicitly granted at install time.
     */
    private fun isReadMediaAudioGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(android.Manifest.permission.READ_MEDIA_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true // Pre-Android-13: uses READ_EXTERNAL_STORAGE or implicit access
        }
    }

    /**
     * Requests READ_MEDIA_AUDIO permission on Android 13+.
     * On older versions, immediately returns true.
     */
    private fun requestReadMediaAudio(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (isReadMediaAudioGranted()) {
            result.success(true)
            return
        }

        if (pendingAudioPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "Audio permission request already in progress", null)
            return
        }

        pendingAudioPermissionResult = result
        requestPermissions(
            arrayOf(android.Manifest.permission.READ_MEDIA_AUDIO),
            REQUEST_READ_MEDIA_AUDIO
        )
    }

    /**
     * Check if POST_NOTIFICATIONS is granted.
     * On Android 13+, this is a runtime permission.
     * On older versions, notifications are always enabled by default.
     * 
     * This uses the REAL Android API to check the actual permission status.
     */
    private fun isPostNotificationsGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Check the actual permission status using checkSelfPermission
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true // Pre-Android-13: notifications are always available
        }
    }

    /**
     * Check if the app can schedule exact alarms.
     * On Android 12+, this requires SCHEDULE_EXACT_ALARM or USE_EXACT_ALARM permission.
     * On older versions, exact alarms are always allowed.
     * 
     * This uses the REAL Android AlarmManager API to check the actual capability.
     */
    private fun isExactAlarmGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // This is the REAL Android API check for exact alarm capability
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    /**
     * Check if fullscreen intent notifications are allowed.
     * On Android 12+, the user can disable fullscreen intents in
     * notification settings per app. We check the NotificationManager policy.
     * 
     * This uses the REAL Android NotificationManager API to check the actual policy.
     */
    private fun isFullScreenIntentAllowed(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return manager.canUseFullScreenIntent()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return checkSelfPermission(android.Manifest.permission.USE_FULL_SCREEN_INTENT) ==
                PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    /**
     * Check whether battery optimization is disabled for this app.
     * On many OEM devices (Xiaomi, Samsung, OnePlus, etc.), the system
     * aggressively kills background services unless the app is whitelisted.
     */
    private fun isBatteryOptimizationDisabled(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    // ---------------------------------------------------------------------------
    // Settings redirection methods
    // ---------------------------------------------------------------------------

    /**
     * Open the app's system settings page.
     */
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    /**
     * Open the app's notification settings page (Android 8+).
     */
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, CHANNEL_TASK_ALARMS)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        startActivity(intent)
    }

    private fun requestPostNotifications(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        if (isPostNotificationsGranted()) {
            result.success(true)
            return
        }

        if (pendingPostNotificationResult != null) {
            result.error("REQUEST_IN_PROGRESS", "Notification permission request already in progress", null)
            return
        }

        pendingPostNotificationResult = result
        requestPermissions(
            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_POST_NOTIFICATIONS
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPostNotificationResult?.success(granted)
            pendingPostNotificationResult = null
        } else if (requestCode == REQUEST_READ_MEDIA_AUDIO) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingAudioPermissionResult?.success(granted)
            pendingAudioPermissionResult = null
        }
    }

    /**
     * Open the exact alarm permission settings page (Android 12+).
     */
    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    /**
     * Open battery optimization settings so the user can whitelist the app.
     * On Android 6+ (API 23), this opens the system's battery optimization
     * screen. The user must manually select "Don't optimize" for this app.
     */
    private fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    /**
     * Open Android 14+'s special app access screen for full-screen intents.
     */
    private fun openFullScreenIntentSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.fromParts("package", packageName, null)
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, CHANNEL_TASK_ALARMS)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        startActivity(intent)
    }

    // ---------------------------------------------------------------------------
    // Notification Channels (must match Dart side)
    // ---------------------------------------------------------------------------

    /**
     * Creates or updates all Android notification channels.
     *
     * Each channel has:
     *   - Proper importance for the content type
     *   - Full-screen intent behaviour for critical task alarms
     *   - Bypass DND / lock-screen visibility for task reminders
     *   - Custom alarm sound (if available) or the system default alarm tone
     *   - Lights and vibration enabled where appropriate
     */
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // ── 1. Task Alarms (HIGH importance) ─────────────────────────────
        // Used for scheduled task reminders, overdue alerts, and fullscreen
        // alarms.  These MUST bypass silent / DND mode on Android 12+ and
        // show on the lock screen.
        val taskAlarmChannel = NotificationChannel(
            CHANNEL_TASK_ALARMS,
            "Task Alarms",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Scheduled task reminders and overdue alerts"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)

            // Use the system default alarm ringtone for task reminders
            val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(alarmUri, audioAttrs)

            // Bypass DND on Android 10+ (API 29) for critical task alarms
            // Note: setBypassDnd was added in API 29 (Android 10), not API 33
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setBypassDnd(true)
            }

            // Show on lock screen
            // On Android 12+, full-screen intents require USE_FULL_SCREEN_INTENT permission
            // Notifications are posted via NotificationCompat.Builder.setFullScreenIntent()

        }
        manager.createNotificationChannel(taskAlarmChannel)

        // ── 2. Bedtime Planner (DEFAULT importance) ──────────────────────
        // Quiet but noticeable nudge to plan tomorrow. No fullscreen, no
        // DND bypass — just a gentle evening reminder.
        val bedtimeChannel = NotificationChannel(
            CHANNEL_BEDTIME,
            "Bedtime Planner",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Gentle daily planning reminders at bedtime"
            enableVibration(true)
            enableLights(false)
            setShowBadge(false)

            // Use a gentle notification sound
            val notificationUri: Uri =
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: Settings.System.DEFAULT_NOTIFICATION_URI
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(notificationUri, audioAttrs)

            // Show on lock screen (but not fullscreen)
            // Lock screen visibility handled by importance level (IMPORTANCE_DEFAULT)

        }
        manager.createNotificationChannel(bedtimeChannel)

        // ── 3. General Reminders (DEFAULT importance) ────────────────────
        // Used for goal milestones, streak warnings, and other productivity
        // notifications that are not time-critical task alarms.
        val generalChannel = NotificationChannel(
            CHANNEL_GENERAL,
            "General Reminders",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Goal milestones, streak warnings, and productivity alerts"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)

            val notificationUri: Uri =
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: Settings.System.DEFAULT_NOTIFICATION_URI
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(notificationUri, audioAttrs)

            // Lock screen visibility handled by importance level (IMPORTANCE_DEFAULT)

        }
        manager.createNotificationChannel(generalChannel)

        // Legacy alarm channel.
        // Kept with high importance for older installs that already have this channel.
        val legacyAlarmChannel = NotificationChannel(
            "alarms",
            "Alarms",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "General task alarms"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setBypassDnd(true)
            }
            // Lock screen visibility handled by importance level (IMPORTANCE_HIGH)
            // Full-screen intents set via NotificationCompat.Builder.setFullScreenIntent()
        }
        manager.createNotificationChannel(legacyAlarmChannel)

        // ── 5. Full-screen alarm (HIGH importance) ─────────────────────────
        // Explicitly registered here on app startup so the system knows about
        // this channel even before AlarmForegroundService starts. Mirrors the
        // configuration in AlarmForegroundService.createChannel().
        // Using a valid alarm URI instead of setSound(null, null) prevents
        // Xiaomi and other OEMs from deprioritizing the channel.
        val fullScreenAlarmChannel = NotificationChannel(
            CHANNEL_FULL_SCREEN_ALARM,
            "Full-screen alarms",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Critical full-screen alarm playback"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)

            // Provide a valid alarm URI so OEMs (e.g. Xiaomi) do NOT
            // deprioritize this channel. The actual looping audio is
            // managed separately by AlarmForegroundService.MediaPlayer.
            val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(alarmUri, audioAttrs)

            // Bypass DND on Android 10+ (API 29)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setBypassDnd(true)
            }

        }
        manager.createNotificationChannel(fullScreenAlarmChannel)
    }

    /**
     * Log current permission status for debugging.
     */
    private fun logPermissionStatus() {
        // Permission status logging removed for production
    }

    // ---------------------------------------------------------------------------
    // Alarm Settings Persistence (SharedPreferences)
    // ---------------------------------------------------------------------------

    /**
     * Save alarm settings to SharedPreferences for use by native Android code.
     * This allows AlarmReceiver and native alarm activities to respect user preferences.
     */
    private fun saveAlarmSettings(
        fullscreenEnabled: Boolean,
        vibrationEnabled: Boolean,
        alarmSoundEnabled: Boolean,
        snoozeEnabled: Boolean
    ) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_FULLSCREEN_ENABLED, fullscreenEnabled)
            .putBoolean(KEY_VIBRATION_ENABLED, vibrationEnabled)
            .putBoolean(KEY_ALARM_SOUND_ENABLED, alarmSoundEnabled)
            .putBoolean(KEY_SNOOZE_ENABLED, snoozeEnabled)
            .apply()
    }

    /**
     * Retrieve alarm settings from SharedPreferences.
     * Returns a map with all settings.
     */
    private fun getAlarmSettings(): Map<String, Boolean> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val settings = mapOf(
            KEY_FULLSCREEN_ENABLED to prefs.getBoolean(KEY_FULLSCREEN_ENABLED, true),
            KEY_VIBRATION_ENABLED to prefs.getBoolean(KEY_VIBRATION_ENABLED, true),
            KEY_ALARM_SOUND_ENABLED to prefs.getBoolean(KEY_ALARM_SOUND_ENABLED, true),
            KEY_SNOOZE_ENABLED to prefs.getBoolean(KEY_SNOOZE_ENABLED, true)
        )
        return settings
    }

    /**
     * Check if fullscreen alarms are enabled (for use by AlarmReceiver).
     */
    fun isFullscreenAlarmEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_FULLSCREEN_ENABLED, true)
    }

    /**
     * Check if vibration is enabled for native alarm playback.
     */
    fun isVibrationEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_VIBRATION_ENABLED, true)
    }

    /**
     * Check if alarm sound is enabled for native alarm playback.
     */
    fun isAlarmSoundEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ALARM_SOUND_ENABLED, true)
    }

    /**
     * Extract the alarmId from a JSON payload string.
     * Returns null if the payload doesn't contain an identifiable alarmId.
     */
    private fun extractAlarmId(payloadJson: String): String? {
        return runCatching {
            JSONObject(payloadJson).optString("alarmId", null)?.takeIf { it.isNotBlank() }
        }.getOrNull()
    }
}
