package com.example.habit_up

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
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
        private const val WAKE_LOCK_TIMEOUT_MS = 10_000L

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
        val payloadJson = intent.getStringExtra(EXTRA_PAYLOAD_JSON)
            ?: legacyPayload(intent)

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP,
            WAKE_LOCK_TAG
        )

        try {
            wakeLock.acquire(WAKE_LOCK_TIMEOUT_MS)

            AlarmPayloadStore.removeScheduled(
                context.applicationContext,
                AlarmScheduler.alarmIdFor(payloadJson)
            )

            AlarmForegroundService.start(context.applicationContext, payloadJson)

            // ── Auto-reschedule bedtime alarm for the next day ─────────────
            // This ensures the bedtime alarm repeats daily in the background
            // without requiring the user to open the app.
            rescheduleNextBedtime(context.applicationContext, payloadJson)
        } catch (_: Exception) {
        } finally {
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
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

            val nextTrigger = System.currentTimeMillis() + 86_400_000L // +24 hours

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
}
