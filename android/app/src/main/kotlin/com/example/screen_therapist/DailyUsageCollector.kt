package com.example.screen_therapist

import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import java.time.ZoneId
import kotlin.math.min
import kotlin.math.max

class DailyUsageCollector(context: Context) {
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private val localZone: ZoneId = ZoneId.systemDefault()

    fun collect(startTime: Long, endTime: Long): Map<String, Any> {
        val boundedStart = max(0L, startTime)
        val boundedEnd = min(System.currentTimeMillis(), endTime)

        if (boundedEnd <= boundedStart) {
            return mapOf(
                "screenTime" to 0L,
                "unlockCount" to 0,
                "lateNightUsage" to 0L,
                "appUsage" to emptyMap<String, Long>()
            )
        }

        val appUsage = collectAppUsage(boundedStart, boundedEnd)
        val unlockCount = countUnlockEvents(boundedStart, boundedEnd)
        val screenTime = calculateScreenTime(boundedStart, boundedEnd)

        val dayStart = java.time.Instant.ofEpochMilli(boundedStart)
            .atZone(localZone)
            .toLocalDate()
            .atStartOfDay(localZone)
            .toInstant()
            .toEpochMilli()
        val lateNightStart = dayStart
        val lateNightEnd = dayStart + (5 * 60 * 60 * 1000L)
        val lateNightWindowStart = max(boundedStart, lateNightStart)
        val lateNightWindowEnd = min(boundedEnd, lateNightEnd)
        val lateNightUsage = if (lateNightWindowEnd > lateNightWindowStart) {
            calculateScreenTime(lateNightWindowStart, lateNightWindowEnd)
        } else {
            0L
        }

        return mapOf(
            "screenTime" to screenTime,
            "unlockCount" to unlockCount,
            "lateNightUsage" to lateNightUsage,
            "appUsage" to appUsage
        )
    }

    private fun collectAppUsage(startTime: Long, endTime: Long): Map<String, Long> {
        val usageStatsList: List<UsageStats> = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val usageMap = linkedMapOf<String, Long>()
        for (stats in usageStatsList) {
            val pkg = stats.packageName ?: continue
            val foreground = stats.totalTimeInForeground
            if (foreground <= 0L) continue
            usageMap[pkg] = (usageMap[pkg] ?: 0L) + foreground
        }
        return usageMap
    }

    private fun countUnlockEvents(startTime: Long, endTime: Long): Int {
        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()
        var unlocks = 0

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.KEYGUARD_HIDDEN) {
                unlocks++
            }
        }

        return unlocks
    }

    private fun calculateScreenTime(startTime: Long, endTime: Long): Long {
        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        var total = 0L
        var screenOnAt: Long? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    if (screenOnAt == null) {
                        screenOnAt = event.timeStamp
                    }
                }

                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    val startedAt = screenOnAt
                    if (startedAt != null) {
                        if (event.timeStamp > startedAt) {
                            total += event.timeStamp - startedAt
                        }
                        screenOnAt = null
                    }
                }
            }
        }

        val ongoingStart = screenOnAt
        if (ongoingStart != null && endTime > ongoingStart) {
            total += endTime - ongoingStart
        }

        return total
    }
}
