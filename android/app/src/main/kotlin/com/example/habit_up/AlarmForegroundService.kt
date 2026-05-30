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
import android.provider.Settings
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

        /**
         * Derive a unique, stable notification ID from the alarm payload's
         * [alarmId].  Same alarmId → same notification ID (updates existing
         * entry in the drawer).  Different alarmIds → different IDs (each
         * alarm gets its own row in the notification drawer).
         *
         * Prevents the problem where multiple simultaneous or near-simultaneous
         * alarms all share the same hardcoded ID and overwrite each other.
         */
        private fun notificationIdFor(payloadJson: String): Int {
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

        fun start(context: Context, payloadJson: String) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PAYLOAD_JSON, payloadJson)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopAudio(context: Context) {
            val intent = Intent(context, AlarmForegroundService::class.java).apply {
                action = ACTION_STOP_AUDIO
            }
            context.startService(intent)
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

    override fun onCreate() {
        super.onCreate()
        createChannel()
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
                val payloadJson = intent?.getStringExtra(EXTRA_PAYLOAD_JSON)
                    ?: AlarmPayloadStore.peek(applicationContext)
                    ?: """{"type":"task","title":"Alarm","description":"Time to focus"}"""

                val alarmId = extractAlarmId(payloadJson)

                val headPayload = AlarmPayloadStore.peek(applicationContext)
                if (headPayload != payloadJson) {
                    AlarmPayloadStore.enqueue(applicationContext, payloadJson)
                }

                // ── Stop any previous alarm audio so only one plays at a time ──
                // When a new alarm fires while another is still ringing, this
                // prevents overlapping alarm sounds.
                stopAllAudio()

                try {
                    startForeground(notificationIdFor(payloadJson), buildNotification(payloadJson))
                } catch (e: Exception) {
                    // startForeground failed
                }

                startLoopingAudio(payloadJson)
                // AlarmActivity is launched via the notification's
                // setFullScreenIntent() — the sole, authoritative path.
                // Direct background startActivity() is intentionally
                // removed because MIUI / HyperOS intercepts and blocks it,
                // causing the full-screen alarm to silently fail.
                return START_STICKY
            }
            else -> {
                return START_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopAllAudio()
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
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

        // ── Full-screen intent: opens AlarmActivity ─────────────────────
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

        // ── Content intent: opens MainActivity when the banner is tapped ─
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

        // ── Honor the alarm_sound_enabled preference ───────────────────
        if (!isAlarmSoundEnabled()) {
            return
        }

        // ── Already playing for this alarm ID?  Then we're done ────────
        if (mediaPlayers.containsKey(alarmId)) {
            return
        }

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
            return
        }

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
                    runCatching { p.reset(); p.release() }
                    mediaPlayers.remove(alarmId)
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
        }.onFailure { _ ->
            // MediaPlayer failed
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
        }
        manager.createNotificationChannel(channel)
    }
}
