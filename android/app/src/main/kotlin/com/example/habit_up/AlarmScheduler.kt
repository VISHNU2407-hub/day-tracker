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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (_: Exception) {
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
                // Alarm expired while device was off — skip and remove from store
                expiredCount++
            }
        }

        // Purge expired entries from the persistent store in one atomic write
        AlarmPayloadStore.keepOnlyScheduled(context, alarmIdsToKeep)

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
