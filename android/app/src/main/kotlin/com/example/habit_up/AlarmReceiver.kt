package com.example.habit_up

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import org.json.JSONObject
import java.util.Locale

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_TASK_TITLE = "task_title"
        const val EXTRA_TASK_MESSAGE = "task_message"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_PAYLOAD_JSON = "payload_json"
        private const val WAKE_LOCK_TAG = "HabitUp:AlarmWakeLock"
        private const val WAKE_LOCK_TIMEOUT_MS = 30_000L

        // ── Direct audio player (from BroadcastReceiver) ────────────────
        // Stored in companion object to prevent garbage collection after
        // onReceive() returns. The player keeps running on the receiver's
        // wake lock for ~30 seconds.
        private var directAudioPlayer: MediaPlayer? = null

        /**
         * Stop any audio playing directly from the BroadcastReceiver.
         * Called by AlarmForegroundService when it successfully starts and
         * takes over audio playback.
         */
        fun stopDirectAudio() {
            directAudioPlayer?.let {
                runCatching {
                    if (it.isPlaying) it.stop()
                    it.reset()
                    it.release()
                }.onFailure { _ -> }
                directAudioPlayer = null
            }
        }

        fun createPendingIntent(
            context: Context,
            requestCode: Int,
            taskId: String,
            taskTitle: String? = null,
            taskMessage: String? = null,
            notificationId: Int
        ): PendingIntent {
            val payload = JSONObject()
                .put("type", "task")
                .put("alarmId", taskId)
                .put("taskId", taskId)
                .put("taskName", taskTitle ?: "Task alarm")
                .put("description", taskMessage ?: "")
                .put("notificationId", notificationId)
                .toString()

            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(EXTRA_PAYLOAD_JSON, payload)
                putExtra(EXTRA_TASK_ID, taskId)
                putExtra(EXTRA_TASK_TITLE, taskTitle)
                putExtra(EXTRA_TASK_MESSAGE, taskMessage)
                putExtra(EXTRA_NOTIFICATION_ID, notificationId)
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmDiag", "--- onReceive ENTERED ---")
        Log.d("AlarmDiag", "intent.action=" + intent.action +
            " extras=" + intent.extras?.keySet()?.joinToString(","))
        val directPayload = intent.getStringExtra(EXTRA_PAYLOAD_JSON)
        val payloadJson = directPayload ?: legacyPayload(intent).also {
            Log.w("AlarmDiag", "#0: EXTRA_PAYLOAD_JSON missing, using legacyPayload fallback")
        }

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        // ── Wake lock handoff ─────────────────────────────────────────────
        // CRITICAL: Do NOT release this wake lock immediately! The wake lock
        // is acquired with a 30-second timeout and auto-releases after that.
        // 
        // Reason: startForegroundService() is ASYNCHRONOUS — the service's
        // onStartCommand() runs AFTER onReceive() returns. If we release the
        // wake lock in a finally block, there is a gap with NO wake lock
        // before the foreground service acquires its own. During this gap,
        // the CPU can enter deep sleep (power button pressed, screen off)
        // and kill the MediaPlayer before it even starts.
        //
        // By keeping the wake lock held for 30 seconds, we guarantee the
        // foreground service has enough time to start and acquire its own
        // PARTIAL_WAKE_LOCK (which is released when audio stops).
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP,
            WAKE_LOCK_TAG
        )

        try {
            wakeLock.acquire(WAKE_LOCK_TIMEOUT_MS)
        } catch (_: SecurityException) {
            // Wake lock not permitted — continue anyway
        }

        try {
            AlarmPayloadStore.removeScheduled(
                context.applicationContext,
                AlarmScheduler.alarmIdFor(payloadJson)
            )

            // ── Direct notification (CRITICAL for lock screen) ──────────────
            // Post the alarm notification DIRECTLY from the broadcast receiver,
            // BEFORE starting the foreground service. This is the KEY fix for
            // lock screen alarms:
            //
            // When the phone is LOCKED, Android may block or delay
            // startForegroundService() — but the broadcast receiver ALWAYS runs
            // when AlarmManager fires. By posting the notification here, we
            // guarantee it shows on the lock screen with the full-screen intent
            // to open AlarmActivity.
            //
            // The foreground service (started below) is a secondary channel
            // for looping audio and wake lock management.
            AlarmForegroundService.postDirectNotification(
                context.applicationContext,
                payloadJson
            )

            // ── Play audio DIRECTLY from the BroadcastReceiver ────────────
            // CRITICAL: On Android 12+, when the phone is locked and the app
            // has been in the background for an extended period, the system
            // may BLOCK or DELAY startForegroundService() from a
            // BroadcastReceiver. This is especially aggressive on HyperOS
            // (Xiaomi/MIUI), OneUI (Samsung), and ColorOS (Oppo/OnePlus).
            //
            // By playing audio directly from the receiver (using the 30-second
            // wake lock that keeps the CPU awake), we guarantee the user hears
            // the alarm EVEN if the foreground service never starts. This is
            // the "nuclear option" that bypasses all foreground service
            // restrictions.
            //
            // The MediaPlayer runs in the receiver's process, which has the
            // PARTIAL_WAKE_LOCK for 30 seconds. After 30 seconds, the wake
            // lock auto-releases — by which time either:
            //   1. The foreground service has started and acquired its own
            //      wake lock (continues playing), OR
            //   2. The user has opened the app (process is now foreground), OR
            //   3. The audio fades out gracefully
            playDirectAudio(context.applicationContext, payloadJson)

            // ── Foreground service for looping audio ─────────────────────
            // Starts the service that plays the looping alarm sound and
            // manages the persistent wake lock. This may be delayed or
            // blocked when the phone is locked, which is why the direct
            // notification above is the primary lock-screen path.
            //
            // If the service starts successfully, it will acquire its own
            // PARTIAL_WAKE_LOCK (10-minute timeout) and take over audio
            // playback. The direct audio from the receiver will still be
            // playing (brief overlap) — the service's stopAllAudio() handles
            // cleanup by calling stopDirectAudio().
            AlarmForegroundService.start(context.applicationContext, payloadJson)
        } catch (e: Exception) {
            Log.e("AlarmDiag", "OUTER CATCH: ${e.javaClass.simpleName}: ${e.message}", e)
        }

        // ── Auto-reschedule bedtime alarm for the next day ───────────────
        // CRITICAL: This MUST run OUTSIDE the try-catch above. On Android 12+,
        // startForegroundService() can throw an IllegalStateException when the
        // phone is locked (Doze mode restrictions). If rescheduleNextBedtime()
        // is inside the same try block, that exception would prevent it from
        // running — and the next day's bedtime alarm would never be scheduled.
        // After a reboot, there would be nothing in the store to restore.
        
        // Use a separate try-catch so it runs independently.
        try {
            rescheduleNextBedtime(context.applicationContext, payloadJson)
        } catch (_: Exception) {
        }
        // NOTE: Wake lock is deliberately NOT released here. It will
        // auto-release after WAKE_LOCK_TIMEOUT_MS (30 seconds), by which
        // time the foreground service will have acquired its own wake lock.
    }

    /**
     * If the fired alarm is a bedtime alarm, automatically schedule the next
     * occurrence for the following day (24 hours from now). This makes the
     * bedtime alarm repeat daily in the background without relying on the
     * Flutter app being opened or `main.dart`'s initialisation logic.
     *
     * Preserves the user's custom alarm sound URI (selected in the Flutter
     * UI and persisted via [MainActivity.Companion.getCustomSoundUri]) so
     * auto-rescheduled bedtime alarms also use the preferred sound.
     */
    private fun rescheduleNextBedtime(context: Context, payloadJson: String) {
        runCatching {
            val payload = JSONObject(payloadJson)
            if (payload.optString("type") != "bedtime") return

            // Honour the user's bedtime reminder preference persisted by the
            // Dart side via saveBedtimeReminderEnabled.  If disabled, do NOT
            // auto-reschedule — the next app-launch will respect the toggle.
            val prefs = context.getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            val bedtimeReminderEnabled = prefs.getBoolean("bedtime_reminder_enabled", true)
            if (!bedtimeReminderEnabled) {
                return
            }

            // Use the user's preferred bedtime hour/minute for accurate next-day
            // scheduling, rather than blindly adding 24 hours.
            val bedtimeHour = MainActivity.getBedtimeHour(context)
            val bedtimeMinute = MainActivity.getBedtimeMinute(context)

            val calendar = java.util.Calendar.getInstance()
            calendar.set(java.util.Calendar.HOUR_OF_DAY, bedtimeHour)
            calendar.set(java.util.Calendar.MINUTE, bedtimeMinute)
            calendar.set(java.util.Calendar.SECOND, 0)
            calendar.set(java.util.Calendar.MILLISECOND, 0)

            // If today's bedtime has already passed, advance to tomorrow
            // (e.g. alarm fired at 10:30 PM, bedtime is 9 PM → next is tomorrow 9 PM)
            val now = System.currentTimeMillis()
            if (calendar.timeInMillis <= now) {
                calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)
            }

            val nextTrigger = calendar.timeInMillis

            // ── Preserve custom sound URI from the original payload ─────
            // First try the current payload, then fall back to SharedPreferences
            // (which was saved by Flutter's AlarmSoundService through the method channel).
            var customSoundUri = payload.optString("customSoundUri", null)?.takeIf { it.isNotBlank() }
            if (customSoundUri == null) {
                customSoundUri = MainActivity.getCustomSoundUri(context)
            }

            val nextPayload = JSONObject()
                .put("type", "bedtime")
                .put("title", "Plan Tomorrow")
                .put("description", "Time to plan your goals for tomorrow")
                .put("alarmId", "bedtime_alarm")
                .put("taskId", "bedtime")
                .put("taskName", "Plan Tomorrow")
                .put("notificationId", 9999)

            if (customSoundUri != null) {
                nextPayload.put("customSoundUri", customSoundUri)
            }

            AlarmScheduler.schedule(context, nextTrigger, nextPayload.toString())
        }.onFailure { _ ->
        }
    }

    private fun legacyPayload(intent: Intent): String {
        val taskId = intent.getStringExtra(EXTRA_TASK_ID)
        val taskTitle = intent.getStringExtra(EXTRA_TASK_TITLE)
        val taskMessage = intent.getStringExtra(EXTRA_TASK_MESSAGE)
        val notId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
        return JSONObject()
            .put("type", "task")
            .put("alarmId", taskId ?: "legacy_alarm_$notId")
            .put("taskId", taskId ?: "")
            .put("taskName", taskTitle ?: "Task alarm")
            .put("description", taskMessage ?: "")
            .put("notificationId", notId)
            .toString()
    }

    /**
     * Play alarm audio directly from the BroadcastReceiver, bypassing the
     * foreground service entirely. This is the key fix for locked devices
     * where startForegroundService() is blocked.
     *
     * Uses the 30-second wake lock (acquired in onReceive()) to keep the
     * CPU awake for uninterrupted playback. The audio loops until:
     *   1. The foreground service starts and takes over (calls stopDirectAudio())
     *   2. The wake lock expires (~30s)
     *   3. The user opens the app
     *
     * @param context Application context
     * @param payloadJson The alarm payload JSON
     */
    private fun playDirectAudio(context: Context, payloadJson: String) {
        // Stop any previous direct audio (shouldn't happen, but be safe)
        stopDirectAudio()

        // ── Honor the alarm_sound_enabled preference ───────────────────
        Log.d("AlarmDiag", "playDirectAudio ENTERED")

        val prefs = context.getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("alarm_sound_enabled", true)) {
            Log.w("AlarmDiag", "playDirectAudio EXIT #4: alarm_sound_enabled is false")
            return
        }

        val payload = runCatching { JSONObject(payloadJson) }.getOrNull()
        if (payload == null) {
            Log.w("AlarmDiag", "playDirectAudio EXIT #5: invalid payload JSON, len=${payloadJson.length}")
            return
        }

        // ── Resolve the alarm sound URI ───────────────────────────────
        // Priority order:
        //   1. Custom sound URI from payload (user-selected in Flutter UI)
        //   2. soundUri from payload (legacy/explicit)
        //   3. System default alarm ringtone
        //   4. Settings.System default alarm URI (last resort)
        val customSoundPath = payload.optString("customSoundUri")?.takeIf { it.isNotBlank() }
        val explicitUri = payload.optString("soundUri")?.takeIf { it.isNotBlank() }

        val alarmUri: Uri = try {
            customSoundPath?.let { path ->
                val uri = Uri.parse(path)
                // Verify the file exists for file:// URIs
                val file = java.io.File(uri.path ?: path)
                if (file.exists()) uri else null
            } ?: explicitUri?.let { Uri.parse(it) }
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
        } catch (_: Exception) {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: Settings.System.DEFAULT_ALARM_ALERT_URI
        }

        if (alarmUri == Uri.EMPTY) {
            Log.w("AlarmDiag", "playDirectAudio EXIT #6: alarmUri == Uri.EMPTY")
            return
        }
        Log.d("AlarmDiag", "playDirectAudio: playing alarmUri=$alarmUri")

        // ── Create and start the MediaPlayer ─────────────────────────
        runCatching {
            val player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(context, alarmUri)
                isLooping = true
                setVolume(1.0f, 1.0f)

                setOnErrorListener { p, what, extra ->
                    runCatching {
                        if (p.isPlaying) p.stop()
                        p.reset()
                        p.release()
                    }.onFailure { _ -> }
                    directAudioPlayer = null
                    true
                }

                prepare()
                start()
            }

            // Store the reference so the GC doesn't collect it after
            // onReceive() returns. The player keeps running on a separate
            // thread managed by MediaPlayer internally.
            directAudioPlayer = player
            Log.d("AlarmDiag", "playDirectAudio SUCCESS: player assigned")
        }.onFailure { ex ->
            Log.e("AlarmDiag", "playDirectAudio FAILURE #7: ex=${ex.message}", ex)
        }
    }
}
