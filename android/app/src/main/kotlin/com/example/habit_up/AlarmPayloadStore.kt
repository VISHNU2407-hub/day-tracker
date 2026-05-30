package com.example.habit_up

import android.content.Context
import org.json.JSONArray

object AlarmPayloadStore {
    private const val PREFS = "native_alarm_payloads"
    private const val KEY_QUEUE = "queue"
    private const val KEY_SCHEDULED = "scheduled"

    @Synchronized
    fun enqueue(context: Context, payloadJson: String) {
        val queue = readArray(context, KEY_QUEUE)
        queue.put(payloadJson)
        writeArray(context, KEY_QUEUE, queue)
    }

    @Synchronized
    fun peek(context: Context): String? {
        val queue = readArray(context, KEY_QUEUE)
        return if (queue.length() == 0) null else queue.optString(0, null)
    }

    @Synchronized
    fun pop(context: Context): String? {
        val queue = readArray(context, KEY_QUEUE)
        if (queue.length() == 0) return null

        val first = queue.optString(0, null)
        val remaining = JSONArray()
        for (index in 1 until queue.length()) {
            remaining.put(queue.optString(index))
        }
        writeArray(context, KEY_QUEUE, remaining)
        return first
    }

    @Synchronized
    fun upsertScheduled(context: Context, alarmId: String, triggerAtMillis: Long, payloadJson: String) {
        val scheduled = readArray(context, KEY_SCHEDULED)
        val next = JSONArray()
        for (index in 0 until scheduled.length()) {
            val item = scheduled.optJSONObject(index) ?: continue
            if (item.optString("alarmId") != alarmId) next.put(item)
        }
        next.put(
            org.json.JSONObject()
                .put("alarmId", alarmId)
                .put("triggerAtMillis", triggerAtMillis)
                .put("payload", payloadJson)
        )
        writeArray(context, KEY_SCHEDULED, next)
    }

    @Synchronized
    fun removeScheduled(context: Context, alarmId: String) {
        val scheduled = readArray(context, KEY_SCHEDULED)
        val next = JSONArray()
        for (index in 0 until scheduled.length()) {
            val item = scheduled.optJSONObject(index) ?: continue
            if (item.optString("alarmId") != alarmId) next.put(item)
        }
        writeArray(context, KEY_SCHEDULED, next)
    }

    @Synchronized
    fun scheduled(context: Context): JSONArray = readArray(context, KEY_SCHEDULED)

    /**
     * Rewrite the scheduled store to keep only entries whose [alarmId] is
     * present in [alarmIdsToKeep]. All other entries are permanently removed.
     * This is an O(n) single-write operation — far more efficient than calling
     * [removeScheduled] repeatedly in a loop.
     */
    @Synchronized
    fun keepOnlyScheduled(context: Context, alarmIdsToKeep: Set<String>) {
        val scheduled = readArray(context, KEY_SCHEDULED)
        val next = JSONArray()
        for (index in 0 until scheduled.length()) {
            val item = scheduled.optJSONObject(index) ?: continue
            val alarmId = item.optString("alarmId", "")
            if (alarmId in alarmIdsToKeep) {
                next.put(item)
            }
        }
        writeArray(context, KEY_SCHEDULED, next)
    }

    private fun readArray(context: Context, key: String): JSONArray {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(key, "[]") ?: "[]"
        return runCatching { JSONArray(raw) }.getOrDefault(JSONArray())
    }

    private fun writeArray(context: Context, key: String, array: JSONArray) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(key, array.toString())
            .apply()
    }
}
