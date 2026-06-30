package com.gymstreaklabs.wakesaga

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

class MainActivity : FlutterActivity() {
    private val channelName = "wakesaga/alarm_engine"
    private val preferencesName = "wakeSaga.alarmEngine.v1"
    private val scheduledKey = "scheduled"
    private val pendingLaunchKey = "pendingLaunch"
    private val alarmFireAction = "com.gymstreaklabs.wakesaga.ALARM_FIRE"
    private val alarmIdExtra = "alarmId"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result -> handleAlarmCall(call, result) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        recordLaunchIntent(intent, "coldStart")
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        recordLaunchIntent(intent, "warmAction")
    }

    private fun handleAlarmCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> result.success(capabilityMap())
            "schedule" -> {
                val plan = call.arguments as? Map<*, *>
                if (plan == null) {
                    result.error("BAD_PLAN", "Expected alarm plan map.", null)
                    return
                }
                result.success(schedule(plan))
            }
            "cancel" -> {
                val arguments = call.arguments as? Map<*, *>
                val alarmId = arguments?.get("alarmId") as? String
                result.success(cancel(alarmId))
            }
            "listScheduled" -> result.success(listScheduled())
            "consumeLaunchAlarm" -> result.success(consumeLaunchAlarm())
            else -> result.notImplemented()
        }
    }

    private fun capabilityMap(): Map<String, Any> = mapOf(
        "alarmKit" to "unavailable",
        "notifications" to "unavailable",
        "exactAlarm" to "available",
        "fullScreenIntent" to "unavailable",
        "foregroundService" to "unavailable",
        "compatibilityMode" to true,
        "message" to "Android setAlarmClock compatibility path ready"
    )

    private fun schedule(plan: Map<*, *>): Map<String, Any?> {
        val alarmId = plan["id"] as? String ?: "wake-${System.currentTimeMillis()}"
        val scheduledAt = nextFireInstant(plan)
        val pendingIntent = launchPendingIntent(alarmId, PendingIntent.FLAG_UPDATE_CURRENT)
            ?: error("Could not create alarm launch intent.")
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(scheduledAt.toEpochMilli(), pendingIntent),
            pendingIntent
        )

        val scheduled = mapOf(
            "plan" to plistSafeMap(plan),
            "scheduledFor" to DateTimeFormatter.ISO_INSTANT.format(scheduledAt),
            "engineMode" to "android-setAlarmClock"
        )
        storeScheduled(scheduled)
        return scheduled
    }

    private fun cancel(alarmId: String?): Boolean {
        if (alarmId.isNullOrBlank()) return false
        val pendingIntent = launchPendingIntent(
            alarmId,
            PendingIntent.FLAG_NO_CREATE
        )
        if (pendingIntent != null) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
        val remaining = listScheduled().filterNot { item ->
            val plan = item["plan"] as? Map<*, *>
            plan?.get("id") == alarmId
        }
        storeScheduledList(remaining)
        return true
    }

    private fun listScheduled(): List<Map<String, Any?>> {
        val raw = preferences().getString(scheduledKey, "[]") ?: "[]"
        val array = JSONArray(raw)
        return List(array.length()) { index ->
            jsonObjectToMap(array.getJSONObject(index))
        }
    }

    private fun consumeLaunchAlarm(): Map<String, Any?>? {
        val preferences = preferences()
        val raw = preferences.getString(pendingLaunchKey, null) ?: return null
        preferences.edit().remove(pendingLaunchKey).apply()
        return jsonObjectToMap(JSONObject(raw))
    }

    private fun recordLaunchIntent(intent: Intent?, source: String): Boolean {
        if (intent == null) return false
        val data = intent.data
        val isAlarmAction = intent.action == alarmFireAction
        val isAlarmUrl = data?.scheme == "wakesaga" && data.host == "alarm"
        if (!isAlarmAction && !isAlarmUrl) return false

        val alarmId = intent.getStringExtra(alarmIdExtra)
            ?: data?.getQueryParameter("alarmId")
            ?: latestScheduledAlarmId()
            ?: return false
        storePendingLaunch(alarmId, source)
        return true
    }

    private fun storePendingLaunch(alarmId: String, source: String) {
        val launch = JSONObject()
            .put("alarmId", alarmId)
            .put("source", source)
            .put("launchedAt", DateTimeFormatter.ISO_INSTANT.format(Instant.now()))
        preferences().edit().putString(pendingLaunchKey, launch.toString()).apply()
    }

    private fun launchPendingIntent(alarmId: String, flags: Int): PendingIntent? {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = alarmFireAction
            data = Uri.parse("wakesaga://alarm?alarmId=${Uri.encode(alarmId)}")
            putExtra(alarmIdExtra, alarmId)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        return PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            intent,
            flags or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun nextFireInstant(plan: Map<*, *>): Instant {
        val hour = (plan["hour"] as? Number)?.toInt() ?: 6
        val minute = (plan["minute"] as? Number)?.toInt() ?: 30
        val repeatDays = (plan["repeatDays"] as? List<*>)
            ?.mapNotNull { (it as? Number)?.toInt() }
            ?.toSet()
            ?: emptySet()
        var candidate = ZonedDateTime.now(ZoneId.systemDefault())
            .withHour(hour)
            .withMinute(minute)
            .withSecond(0)
            .withNano(0)
        if (!candidate.isAfter(ZonedDateTime.now(ZoneId.systemDefault()))) {
            candidate = candidate.plusDays(1)
        }
        while (repeatDays.isNotEmpty() && !repeatDays.contains(candidate.dayOfWeek.value)) {
            candidate = candidate.plusDays(1)
        }
        return candidate.toInstant()
    }

    private fun storeScheduled(scheduled: Map<String, Any?>) {
        val alarmId = (scheduled["plan"] as? Map<*, *>)?.get("id") as? String ?: return
        val saved = listScheduled()
            .filterNot { item ->
                val plan = item["plan"] as? Map<*, *>
                plan?.get("id") == alarmId
            }
            .toMutableList()
        saved.add(scheduled)
        storeScheduledList(saved)
    }

    private fun storeScheduledList(scheduled: List<Map<String, Any?>>) {
        val array = JSONArray()
        scheduled.forEach { item -> array.put(jsonValue(item)) }
        preferences().edit().putString(scheduledKey, array.toString()).apply()
    }

    private fun latestScheduledAlarmId(): String? =
        listScheduled().lastOrNull()?.let { item ->
            val plan = item["plan"] as? Map<*, *>
            plan?.get("id") as? String
        }

    private fun preferences() = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun plistSafeMap(map: Map<*, *>): Map<String, Any?> =
        map.entries.associate { (key, value) ->
            key.toString() to plistSafeValue(value)
        }

    private fun plistSafeList(list: List<*>): List<Any?> =
        list.map { item -> plistSafeValue(item) }

    private fun plistSafeValue(value: Any?): Any? =
        when (value) {
            is Map<*, *> -> plistSafeMap(value)
            is List<*> -> plistSafeList(value)
            else -> value
        }

    private fun jsonValue(value: Any?): Any =
        when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> JSONObject().apply {
                value.forEach { (key, item) -> put(key.toString(), jsonValue(item)) }
            }
            is List<*> -> JSONArray().apply {
                value.forEach { item -> put(jsonValue(item)) }
            }
            else -> value
        }

    private fun jsonObjectToMap(jsonObject: JSONObject): Map<String, Any?> =
        jsonObject.keys().asSequence().associateWith { key ->
            jsonToValue(jsonObject.get(key))
        }

    private fun jsonArrayToList(jsonArray: JSONArray): List<Any?> =
        List(jsonArray.length()) { index -> jsonToValue(jsonArray.get(index)) }

    private fun jsonToValue(value: Any): Any? =
        when (value) {
            JSONObject.NULL -> null
            is JSONObject -> jsonObjectToMap(value)
            is JSONArray -> jsonArrayToList(value)
            else -> value
        }
}
