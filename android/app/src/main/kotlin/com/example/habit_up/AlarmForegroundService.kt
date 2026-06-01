package com.example.habit_up

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlin.math.absoluteValue
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

class AlarmForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "full_screen_alarm"
        private const val NOTIFICATION_TAG = "full_screen_alarm_tag"
        private const val NOTIFICATION_ID_BASE = 5000
        private const val PENDING_INTENT_REQUEST_BASE = 6000
        const val ACTION_START = "com.example.habit_up.alarm.START"
        const val ACTION_STOP_AUDIO = "com.example.habit_up.alarm.STOP_AUDIO"
        const val ACTION_DISMISS_ALL = "com.example.habit_up.alarm.DISMISS_ALL"
        const val EXTRA_PAYLOAD_JSON = "payload_json"
        const val EXTRA_ALARM_ID = "alarm_id"

        private val CHANNEL_SOUND: Uri by lazy {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
        }

        /**
         * Derive a unique, stable notification ID from the alarm payload's
         * [alarmId].  Same alarmId → same notification ID (updates existing
         * entry in the drawer).  Different alarmIds → different IDs (each
         * alarm gets its own row in the notification drawer).
         *
         * Prevents the problem where multiple simultaneous or near-simultaneous
         * alarms all share the same hardcoded ID and overwrite each other.
         */
        fun notificationIdFor(payloadJson: String): Int {
            val alarmId = runCatching {
                JSONObject(payloadJson).optString("alarmId", "")
            }.getOrDefault("")
            val rawId = if (alarmId.isNotBlank()) alarmId.hashCode() else payloadJson.hashCode()
            return (rawId.absoluteValue % (Int.MAX_VALUE - NOTIFICATION_ID_BASE - 1)) + NOTIFICATION_ID_BASE
        }

        /**
         * Derive a unique PendingIntent request code from the alarm payload.
         * This ensures each notification's tap action opens the correct alarm,
         * avoiding PendingIntent collisions between different alarms.
         */
        private fun pendingRequestCodeFor(payloadJson: String): Int {
            val alarmId = runCatching {
                JSONObject(payloadJson).optString("alarmId", "")
            }.getOrDefault("")
            val rawId = if (alarmId.isNotBlank()) alarmId.hashCode() else payloadJson.hashCode()
            return (rawId.absoluteValue % (Int.MAX_VALUE - PENDING_INTENT_REQUEST_BASE - 1)) + PENDING_INTENT_REQUEST_BASE
        }

        // ── Direct notification posting (from broadcast receiver) ─────────
        // Posts an alarm notification directly via NotificationManager, bypassing
        // the foreground service entirely. This is critical because when the phone
        // is LOCKED, the system may block or delay startForegroundService(). The
        // broadcast receiver (triggered by AlarmManager) always runs, so posting
        // the notification here guarantees it appears on the lock screen.
        //
        // The notification includes:
        //   - Full-screen intent → opens AlarmActivity over the lock screen
        //   - Lock screen visibility → shows content on lock screen
        //   - Alarm category + high importance → proper alerting behavior
        //
        // The foreground service (started separately) handles looping audio.
        private fun buildDirectNotification(context: Context, payloadJson: String): Notification {
            val payload = runCatching { JSONObject(payloadJson) }.getOrNull()
            val title = payload?.optString("taskName")?.takeIf { it.isNotBlank() }
                ?: payload?.optString("title")?.takeIf { it.isNotBlank() }
                ?: if (payload?.optString("type") == "bedtime") "Plan tomorrow" else "Alarm"
            val text = payload?.optString("description")?.takeIf { it.isNotBlank() }
                ?: payload?.optString("message")?.takeIf { it.isNotBlank() }
                ?: "Alarm is ringing"

            val prefs = context.getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            val fullscreenEnabled = prefs.getBoolean("fullscreen_enabled", true)

            // ── Full-screen intent: opens AlarmActivity over the lock screen ─
            val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(AlarmActivity.EXTRA_PAYLOAD_JSON, payloadJson)
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val alarmPendingIntent = PendingIntent.getActivity(
                context,
                pendingRequestCodeFor(payloadJson),
                alarmIntent,
                pendingFlags
            )

            // ── Content intent: opens MainActivity when notification is tapped ─
            val contentIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(AlarmActivity.EXTRA_PAYLOAD_JSON, payloadJson)
            }
            val contentPendingIntent = PendingIntent.getActivity(
                context,
                pendingRequestCodeFor(payloadJson) + 1,
                contentIntent,
                pendingFlags
            )

            // Use the platform-style alarm heads-up notification
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle(title)
                .setContentText(text)
                .setTicker("$title - $text")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(true)
                .setDefaults(
                    NotificationCompat.DEFAULT_LIGHTS or
                    NotificationCompat.DEFAULT_VIBRATE or
                    NotificationCompat.DEFAULT_SOUND
                )
                .setSound(CHANNEL_SOUND)
                .apply {
                    if (fullscreenEnabled) {
                        setFullScreenIntent(alarmPendingIntent, true)
                    }
                    setContentIntent(contentPendingIntent)
                }
                .build()
        }

        fun postDirectNotification(context: Context, payloadJson: String) {
            runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = context.getSystemService(NotificationManager::class.java)
                    // ── Diagnose #1: channel importance check ────────────
                    val existingChannel = manager.getNotificationChannel(CHANNEL_ID)
                    if (existingChannel != null) {
                        Log.d("AlarmDiag", "postDirectNotification: channel exists, importance=" +
                            existingChannel.importance + " (need=${NotificationManager.IMPORTANCE_HIGH})")
                        val channelCanBypassDnd = existingChannel.canBypassDnd()
                        Log.d("AlarmDiag", "postDirectNotification: canBypassDnd=$channelCanBypassDnd")
                    } else {
                        Log.d("AlarmDiag", "postDirectNotification: channel does NOT exist, creating")
                    }

                    val channel = NotificationChannel(
                        CHANNEL_ID,
                        "Full-screen alarms",
                        NotificationManager.IMPORTANCE_HIGH
                    ).apply {
                        description = "Critical full-screen alarm playback"
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                        setSound(CHANNEL_SOUND, AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build())
                        enableVibration(true)
                        enableLights(true)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            setBypassDnd(true)
                        }
                    }
                    manager.createNotificationChannel(channel)
                }

                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                // ── Diagnose #2/#3: POST_NOTIFICATIONS permission ────────
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val granted = context.checkSelfPermission(
                        android.Manifest.permission.POST_NOTIFICATIONS
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    Log.d("AlarmDiag", "postDirectNotification: POST_NOTIFICATIONS granted=$granted")
                } else {
                    Log.d("AlarmDiag", "postDirectNotification: pre-Tiramisu, no permission needed")
                }

                val notifId = notificationIdFor(payloadJson)
                Log.d("AlarmDiag", "postDirectNotification: calling notify(id=$notifId)")
                manager.notify(notifId, buildDirectNotification(context, payloadJson))
                Log.d("AlarmDiag", "postDirectNotification: notify() returned successfully")
            }.onFailure { ex ->
                Log.e("AlarmDiag", "postDirectNotification FAILURE #1/2/3: ${ex.javaClass.simpleName}: ${ex.message}", ex)
            }
        }

        fun start(context: Context, payloadJson: String) {
            Log.d("AlarmDiag", "startForegroundService: called, SDK_INT=${Build.VERSION.SDK_INT}")
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PAYLOAD_JSON, payloadJson)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    context.startForegroundService(intent)
                    Log.d("AlarmDiag", "startForegroundService: returned normally")
                } catch (e: Exception) {
                    Log.e("AlarmDiag", "startForegroundService FAILURE #8: ${e.javaClass.simpleName}: ${e.message}", e)
                    throw e
                }
            } else {
                context.startService(intent)
                Log.d("AlarmDiag", "startService: returned normally (pre-O)")
            }
        }

        fun stopAudio(context: Context, alarmId: String? = null) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_STOP_AUDIO
                if (alarmId != null) {
                    putExtra(EXTRA_ALARM_ID, alarmId)
                }
            }
            context.startService(intent)
        }

        fun dismissAll(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_DISMISS_ALL
            }
            context.startService(intent)
        }
    }

    private val mediaPlayers = ConcurrentHashMap<String, MediaPlayer>()
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    // ── Wake lock: keeps the CPU awake while alarm audio is playing ─────
    // Without this, pressing the power button (screen off) can cause the
    // CPU to enter deep sleep, stopping MediaPlayer playback.
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "HabitUp:AlarmAudioWakeLock"
        )
        // Use a generous 10-minute timeout as a safety net to prevent
        // indefinite CPU wake in edge cases (e.g. the user walks away).
        runCatching {
            wakeLock?.acquire(10 * 60 * 1000L)
        }.onFailure { _ ->
            // Wake lock not granted — continue without it
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                runCatching { it.release() }.onFailure { _ -> }
            }
        }
        wakeLock = null
    }

    // ---------------------------------------------------------------------------
    // Alarm Settings — read user preferences saved by MainActivity
    // ---------------------------------------------------------------------------

    /**
     * Read the [MainActivity]-persisted alarm preferences from SharedPreferences.
     * All settings default to `true` (opt-out model), matching MainActivity.
     */
    private fun isFullscreenEnabled(): Boolean {
        return getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            .getBoolean("fullscreen_enabled", true)
    }

    private fun isVibrationEnabled(): Boolean {
        return getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            .getBoolean("vibration_enabled", true)
    }

    private fun isAlarmSoundEnabled(): Boolean {
        return getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            .getBoolean("alarm_sound_enabled", true)
    }

    /**
     * Extract the stable alarmId from a JSON payload string.
     * Returns a non-blank string on success, or falls back to the whole payload
     * hash as a last-resort key.
     */
    private fun extractAlarmId(payloadJson: String): String {
        return runCatching {
            JSONObject(payloadJson).optString("alarmId", "").takeIf { it.isNotBlank() }
        }.getOrNull() ?: "alarm_${payloadJson.hashCode().absoluteValue}"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // ── IMMEDIATE startForeground() ──────────────────────────────────
        // CRITICAL: On Android 15+, there is a strict timeout between
        // startForegroundService() and startForeground(). If the service
        // fails to call startForeground() quickly enough, it is killed with
        // "Context.startForegroundService() did not then call
        // Service.startForeground()" crash.
        //
        // We call startForeground() FIRST with a safe notification, BEFORE
        // any JSON parsing, wake lock acquisition, or MediaPlayer setup.
        // The notification is updated later with the actual payload content.
        val incomingPayload = intent?.getStringExtra(EXTRA_PAYLOAD_JSON)
            ?: AlarmPayloadStore.peek(applicationContext)

        if (incomingPayload != null) {
            runCatching {
                startForeground(
                    notificationIdFor(incomingPayload),
                    buildNotification(incomingPayload)
                )
            }.onFailure { _ ->
                // startForeground() failed (e.g. POST_NOTIFICATIONS denied).
                // The receiver's direct audio fallback (playDirectAudio in
                // AlarmReceiver) will still play audio even without a
                // foreground notification.
            }
        } else {
            // No payload available yet — show a generic alarm notification
            // so startForeground() succeeds. It will be updated below.
            runCatching {
                startForeground(NOTIFICATION_ID_BASE, buildDefaultNotification())
            }.onFailure { _ -> }
        }

        when (intent?.action) {
            ACTION_STOP_AUDIO -> {
                val alarmId = intent.getStringExtra(EXTRA_ALARM_ID)
                if (alarmId != null) {
                    stopLoopingAudio(alarmId)
                } else {
                    stopAllAudio()
                }
                // Only stop the foreground service if no players remain
                if (mediaPlayers.isEmpty()) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                return START_NOT_STICKY
            }
            ACTION_DISMISS_ALL -> {
                stopAllAudio()
                var safety = 0
                while (AlarmPayloadStore.pop(applicationContext) != null && safety < 100) {
                    safety++
                }
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START, null -> {
                val payloadJson = incomingPayload
                    ?: """{"type":"task","title":"Alarm","description":"Time to focus"}"""

                val alarmId = extractAlarmId(payloadJson)

                val headPayload = AlarmPayloadStore.peek(applicationContext)
                if (headPayload != payloadJson) {
                    AlarmPayloadStore.enqueue(applicationContext, payloadJson)
                }

                // ── Take over from receiver's direct audio ────────────────
                // The BroadcastReceiver (AlarmReceiver) may have started
                // direct MediaPlayer audio as a fallback (playDirectAudio)
                // because startForegroundService() can be blocked on locked
                // devices. Now that this service has started successfully,
                // stop the receiver's audio to avoid double-playback.
                // Our own startLoopingAudio() below will handle playback
                // with proper wake lock management.
                AlarmReceiver.stopDirectAudio()

                // ── Stop any previous alarm audio so only one plays ───────
                // When a new alarm fires while another is still ringing, this
                // prevents overlapping alarm sounds.
                stopAllAudio()

                // ── Update the foreground notification with actual payload ─
                // The initial startForeground() call above used a fast
                // notification. Now update it with the proper payload title,
                // text, full-screen intent, etc.
                try {
                    val manager = getSystemService(NotificationManager::class.java)
                    manager.notify(
                        notificationIdFor(payloadJson),
                        buildNotification(payloadJson)
                    )
                } catch (_: Exception) {
                }

                startLoopingAudio(payloadJson)
                // AlarmActivity is launched via the notification's
                // setFullScreenIntent() — the sole, authoritative path.
                // Direct background startActivity() is intentionally
                // removed because MIUI / HyperOS intercepts and blocks it,
                // causing the full-screen alarm to silently fail.
                return START_REDELIVER_INTENT
            }
            else -> {
                return START_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopAllAudio()
        releaseWakeLock()
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // System is removing the task — keep the service alive because
        // the alarm is still ringing. Do NOT stop audio here.
        // The service will continue as a foreground service.
        super.onTaskRemoved(rootIntent)
    }

    /**
     * Build a safe default notification for use when no payload is available.
     * This is used by startForeground() at the top of onStartCommand() when
     * we must call startForeground() immediately but haven't parsed the
     * payload yet.
     */
    private fun buildDefaultNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Alarm")
            .setContentText("Alarm is ringing")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }

    private fun buildNotification(payloadJson: String): Notification {
        val payload = runCatching { JSONObject(payloadJson) }.getOrNull()
        val title = payload?.optString("taskName")?.takeIf { it.isNotBlank() }
            ?: payload?.optString("title")?.takeIf { it.isNotBlank() }
            ?: if (payload?.optString("type") == "bedtime") "Plan tomorrow" else "Alarm"
        val text = payload?.optString("description")?.takeIf { it.isNotBlank() }
            ?: payload?.optString("message")?.takeIf { it.isNotBlank() }
            ?: "Alarm is ringing"

        val fullscreenEnabled = isFullscreenEnabled()
        val vibrationEnabled = isVibrationEnabled()

        // ── Full-screen intent: opens AlarmActivity over the lock screen ─
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(AlarmActivity.EXTRA_PAYLOAD_JSON, payloadJson)
        }
        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val alarmPendingIntent = PendingIntent.getActivity(this, pendingRequestCodeFor(payloadJson), alarmIntent, pendingFlags)

        // ── Content intent: opens MainActivity when the notification banner is tapped ─
        val contentIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AlarmActivity.EXTRA_PAYLOAD_JSON, payloadJson)
        }
        val contentPendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            pendingRequestCodeFor(payloadJson) + 1, // distinct request code
            contentIntent,
            contentPendingIntentFlags
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(text)
            .setTicker("$title - $text")  // Ticker text for lock screen scrolling
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(true)
            .apply {
                // Honor the fullscreen_enabled preference
                if (fullscreenEnabled) {
                    setFullScreenIntent(alarmPendingIntent, true)
                }
                // Clicking the notification banner opens the main app
                setContentIntent(contentPendingIntent)

                // Honor the vibration_enabled preference at the notification level
                if (!vibrationEnabled) {
                    setVibrate(null)
                } else {
                    // Use default system vibration pattern
                    setDefaults(NotificationCompat.DEFAULT_VIBRATE)
                }


            }
            .build()
    }


    private fun startLoopingAudio(payloadJson: String) {
        val alarmId = extractAlarmId(payloadJson)
        Log.d("AlarmDiag", "startLoopingAudio ENTERED: alarmId=$alarmId")

        // ── Honor the alarm_sound_enabled preference ───────────────────
        if (!isAlarmSoundEnabled()) {
            Log.w("AlarmDiag", "startLoopingAudio: alarm_sound_enabled is false, returning")
            return
        }

        // ── Already playing for this alarm ID?  Then we're done ────────
        if (mediaPlayers.containsKey(alarmId)) {
            Log.d("AlarmDiag", "startLoopingAudio: already playing alarmId=$alarmId")
            return
        }

        // ── Acquire wake lock to keep CPU awake while audio plays ─────
        // This is critical — without it, pressing the power button (screen
        // off) lets the CPU sleep, stopping MediaPlayer playback even
        // though the foreground service continues running.
        acquireWakeLock()

        val payload = runCatching { JSONObject(payloadJson) }.getOrNull()

        // ── Try user-selected custom sound from payload ───────────────
        val customSoundPath = payload?.optString("customSoundUri")?.takeIf { it.isNotBlank() }

        var customSoundUri: Uri? = null
        if (customSoundPath != null) {
            try {
                val uri = Uri.parse(customSoundPath)
                val file = java.io.File(uri.path ?: customSoundPath)
                if (file.exists()) {
                    customSoundUri = uri
                }
            } catch (_: Exception) {
            }
        }

        val explicitUri = payload?.optString("soundUri")?.takeIf { it.isNotBlank() }?.let(Uri::parse)

        val alarmUri = customSoundUri
            ?: explicitUri
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: Settings.System.DEFAULT_ALARM_ALERT_URI

        if (alarmUri == Uri.EMPTY) {
            Log.w("AlarmDiag", "startLoopingAudio: alarmUri == Uri.EMPTY, returning")
            return
        }

        Log.d("AlarmDiag", "startLoopingAudio: alarmUri=$alarmUri")
        runCatching {
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(applicationContext, alarmUri)
                isLooping = true
                setVolume(1.0f, 1.0f)

                setOnErrorListener { p, what, extra ->
                    Log.e("AlarmDiag", "startLoopingAudio MediaPlayer ERROR: what=$what extra=$extra")
                    runCatching { p.reset(); p.release() }
                    mediaPlayers.remove(alarmId)
                    if (mediaPlayers.isEmpty()) {
                        releaseWakeLock()
                    }
                    true
                }

                setOnInfoListener { _, what, _ ->
                    false
                }

                setOnCompletionListener {
                    // no-op
                }

                prepare()
                start()
            }

            mediaPlayers[alarmId] = player
            Log.d("AlarmDiag", "startLoopingAudio SUCCESS: player assigned for alarmId=$alarmId")
        }.onFailure { ex ->
            Log.e("AlarmDiag", "startLoopingAudio FAILURE: ${ex.javaClass.simpleName}: ${ex.message}", ex)
            // MediaPlayer failed — release wake lock since no audio
            if (mediaPlayers.isEmpty()) {
                releaseWakeLock()
            }
        }
    }

    private fun stopLoopingAudio(alarmId: String) {
        val player = mediaPlayers.remove(alarmId)
        if (player == null) return
        runCatching {
            if (player.isPlaying) player.stop()
            player.reset()
            player.release()
        }.onFailure { _ -> }
        // Release wake lock when no more players are active
        if (mediaPlayers.isEmpty()) {
            releaseWakeLock()
        }
    }

    private fun stopAllAudio() {
        for ((_, player) in mediaPlayers.entries) {
            runCatching {
                if (player.isPlaying) player.stop()
                player.reset()
                player.release()
            }.onFailure { _ -> }
        }
        mediaPlayers.clear()
        releaseWakeLock()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val vibrationEnabled = isVibrationEnabled()

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Full-screen alarms",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Critical full-screen alarm playback"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            // Set the alarm URI as the channel's sound so the notification
            // properly alerts on the lock screen. The channel sound plays
            // once when the notification is posted; the looping audio is
            // handled separately by the MediaPlayer.
            val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(alarmUri, audioAttrs)
            enableVibration(vibrationEnabled)
            enableLights(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setBypassDnd(true)
            }
            // Ensure the notification shows on the lock screen
            // VISIBILITY_PUBLIC is already set via lockscreenVisibility above
        }
        manager.createNotificationChannel(channel)
    }
}
