package com.example.habit_up

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import kotlin.math.absoluteValue

object AlarmScheduler {
    const val EXTRA_PAYLOAD_JSON = "payload_json"

    fun schedule(
        context: Context,
        triggerAtMillis: Long,
        payloadJson: String,
        persist: Boolean = true
    ) {
        val alarmId = alarmIdFor(payloadJson)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, alarmId, payloadJson)

        try {
            // Use setAlarmClock() for maximum reliability across all Android versions
            // and OEMs (HyperOS, MIUI, OneUI, ColorOS, etc.). setAlarmClock():
            //   - Forces Doze exit *before* the alarm fires (prep phase)
            //   - Shows "next alarm" in the system status bar and lock screen
            //   - Is much harder for OEMs to silently block/delay/batch
            //   - Gives the receiving BroadcastReceiver higher system priority
            //   - Ensures the alarm fires even when app is background/restricted
            //
            // The second parameter (null) means "don't show in system clock UI"
            // — the alarm still gets setAlarmClock priority without cluttering
            // the user's clock UI with task-reminder entries.
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerAtMillis, null),
                pendingIntent
            )
        } catch (_: SecurityException) {
            // setAlarmClock() may throw SecurityException when exact alarm
            // permission is not granted. Fall through to setExact() directly.
            try {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } catch (_: Exception) {}
        } catch (_: IllegalArgumentException) {
            // setAlarmClock() may throw IllegalArgumentException on some OEMs
            // that don't support the API properly. Fall through to setExact().
            try {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } catch (_: Exception) {}
        } catch (_: Exception) {
            // Catch-all: silently fall through — the payload is still persisted
            // and will be rescheduled on next app open or boot.
        }

        if (persist) {
            AlarmPayloadStore.upsertScheduled(context, alarmId, triggerAtMillis, payloadJson)
        }
    }

    fun cancel(context: Context, payloadJson: String) {
        val alarmId = alarmIdFor(payloadJson)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, alarmId, payloadJson))
        AlarmPayloadStore.removeScheduled(context, alarmId)
    }

    fun reschedulePersisted(context: Context) {
        val now = System.currentTimeMillis()
        val scheduled = AlarmPayloadStore.scheduled(context)
        val alarmIdsToKeep = mutableSetOf<String>()
        var expiredCount = 0

        for (index in 0 until scheduled.length()) {
            val item = scheduled.optJSONObject(index) ?: continue
            val triggerAt = item.optLong("triggerAtMillis", 0L)
            val payload = item.optString("payload", "")
            val alarmId = item.optString("alarmId", "")

            if (payload.isBlank()) {
                expiredCount++
                continue
            }

            if (triggerAt > now) {
                // Still in the future — reschedule and keep in store
                alarmIdsToKeep.add(alarmId)
                schedule(context, triggerAt, payload, persist = false)
            } else {
                // Alarm expired while device was off.
                // ── Bedtime alarm: auto-reschedule for today's bedtime ────
                // If this is a bedtime alarm that was missed (e.g. phone was off
                // at bedtime), we schedule it for the next bedtime occurrence
                // instead of silently dropping it.
                val isBedtime = runCatching {
                    JSONObject(payload).optString("type") == "bedtime"
                }.getOrDefault(false)
                if (isBedtime) {
                    val bedtimeHour = MainActivity.getBedtimeHour(context)
                    val bedtimeMinute = MainActivity.getBedtimeMinute(context)

                    val calendar = java.util.Calendar.getInstance()
                    calendar.set(java.util.Calendar.HOUR_OF_DAY, bedtimeHour)
                    calendar.set(java.util.Calendar.MINUTE, bedtimeMinute)
                    calendar.set(java.util.Calendar.SECOND, 0)
                    calendar.set(java.util.Calendar.MILLISECOND, 0)

                    // If today's bedtime has already passed, schedule for tomorrow
                    if (calendar.timeInMillis <= now) {
                        calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)
                    }

                    alarmIdsToKeep.add(alarmId)
                    schedule(context, calendar.timeInMillis, payload, persist = false)
                } else {
                    // Non-bedtime expired alarm — remove from store
                    expiredCount++
                }
            }
        }

        // Purge expired entries from the persistent store in one atomic write
        AlarmPayloadStore.keepOnlyScheduled(context, alarmIdsToKeep)

        // ── Safety net: recreate bedtime alarm if missing from store ──────
        // If no bedtime alarm was found in the store (alarmIdsToKeep doesn't
        // contain "bedtime_alarm"), it means either:
        //   1. The bedtime alarm was never persisted (method channel failure
        //      during initial setup, race condition, etc.)
        //   2. rescheduleNextBedtime() didn't run when the alarm last fired
        //      (e.g., startForegroundService() threw on locked phone)
        //   3. The store was corrupted or cleared
        //
        // In any of these cases, recreate the bedtime alarm from scratch using
        // the user's persisted bedtime hour/minute (if bedtime reminders are
        // enabled). Without this safety net, a single missed reschedule means
        // the bedtime alarm is gone forever after the next reboot.
        if (!alarmIdsToKeep.contains("bedtime_alarm")) {
            val prefs = context.getSharedPreferences("alarm_settings", Context.MODE_PRIVATE)
            val bedtimeReminderEnabled = prefs.getBoolean("bedtime_reminder_enabled", true)
            if (bedtimeReminderEnabled) {
                val bedtimeHour = MainActivity.getBedtimeHour(context)
                val bedtimeMinute = MainActivity.getBedtimeMinute(context)

                val calendar = java.util.Calendar.getInstance()
                calendar.set(java.util.Calendar.HOUR_OF_DAY, bedtimeHour)
                calendar.set(java.util.Calendar.MINUTE, bedtimeMinute)
                calendar.set(java.util.Calendar.SECOND, 0)
                calendar.set(java.util.Calendar.MILLISECOND, 0)

                // If today's bedtime has already passed, schedule for tomorrow
                if (calendar.timeInMillis <= now) {
                    calendar.add(java.util.Calendar.DAY_OF_MONTH, 1)
                }

                val soundUri = MainActivity.getCustomSoundUri(context)

                val payload = JSONObject()
                    .put("type", "bedtime")
                    .put("title", "Plan Tomorrow")
                    .put("description", "Time to plan your goals for tomorrow")
                    .put("alarmId", "bedtime_alarm")
                    .put("taskId", "bedtime")
                    .put("taskName", "Plan Tomorrow")
                    .put("notificationId", 9999)
                    .apply {
                        if (soundUri != null) {
                            put("customSoundUri", soundUri)
                        }
                    }

                schedule(context, calendar.timeInMillis, payload.toString())
            }
        }
    }

    fun alarmIdFor(payloadJson: String): String {
        val json = runCatching { JSONObject(payloadJson) }.getOrNull()
        return json?.optString("alarmId")?.takeIf { it.isNotBlank() }
            ?: json?.optString("taskId")?.takeIf { it.isNotBlank() }
            ?: json?.optString("id")?.takeIf { it.isNotBlank() }
            ?: payloadJson.hashCode().absoluteValue.toString()
    }

    private fun pendingIntent(context: Context, alarmId: String, payloadJson: String): PendingIntent {
        val requestCode = (alarmId.hashCode().absoluteValue % Int.MAX_VALUE) + 120_000
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra(EXTRA_PAYLOAD_JSON, payloadJson)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }
}
