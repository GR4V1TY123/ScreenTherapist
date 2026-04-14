package com.example.screen_therapist

import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import java.time.Instant
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

        // Fix #3: derive 00:00 -> 05:00 window from local calendar date, not from raw offsets.
        val dayLocalDate = Instant.ofEpochMilli(boundedStart)
            .atZone(localZone)
            .toLocalDate()
        val dayStart = dayLocalDate
            .atStartOfDay(localZone)
            .toInstant()
            .toEpochMilli()
        val lateNightStart = dayStart
        val lateNightEnd = dayStart + LATE_NIGHT_HOURS_MS

        // Fix #4: compute total screen time and late night overlap in one pass.
        val screenMetrics = calculateScreenMetrics(
            startTime = boundedStart,
            endTime = boundedEnd,
            lateNightStart = lateNightStart,
            lateNightEnd = lateNightEnd,
        )

        val appUsage = collectAppUsage(boundedStart, boundedEnd)
        val unlockCount = countUnlockEvents(boundedStart, boundedEnd)

        return mapOf(
            "screenTime" to screenMetrics.screenTime,
            "unlockCount" to unlockCount,
            "lateNightUsage" to screenMetrics.lateNightUsage,
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

            // Fix #5: clamp each UsageStats bucket to requested range and prorate foreground time.
            val clampedStart = max(stats.firstTimeStamp, startTime)
            val clampedEnd = min(stats.lastTimeStamp, endTime)
            if (clampedEnd <= clampedStart) continue

            val bucketDuration = stats.lastTimeStamp - stats.firstTimeStamp
            val overlapDuration = clampedEnd - clampedStart
            val foreground = stats.totalTimeInForeground
            if (foreground <= 0L) continue

            val adjustedForeground = if (bucketDuration > 0L) {
                (foreground * overlapDuration) / bucketDuration
            } else {
                foreground
            }
            if (adjustedForeground <= 0L) continue

            usageMap[pkg] = (usageMap[pkg] ?: 0L) + adjustedForeground
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

    private fun calculateScreenMetrics(
        startTime: Long,
        endTime: Long,
        lateNightStart: Long,
        lateNightEnd: Long,
    ): ScreenMetrics {
        if (endTime <= startTime) return ScreenMetrics(0L, 0L)

        // Fix #1: remove 24h state probing and instead extend query by a small buffer.
        val bufferedStart = max(0L, startTime - INITIAL_STATE_BUFFER_MS)
        val events = usageStatsManager.queryEvents(bufferedStart, endTime)
        val event = UsageEvents.Event()

        var isScreenOn = false
        var screenOnAt: Long? = null
        var totalScreenTime = 0L
        var lateNightUsage = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            if (event.eventType != UsageEvents.Event.SCREEN_INTERACTIVE &&
                event.eventType != UsageEvents.Event.SCREEN_NON_INTERACTIVE
            ) {
                continue
            }

            val ts = event.timeStamp

            // Fix #1 + #2: use buffered events before start to establish initial state
            // while ignoring duplicate transitions.
            if (ts < startTime) {
                when (event.eventType) {
                    UsageEvents.Event.SCREEN_INTERACTIVE -> {
                        if (!isScreenOn) {
                            isScreenOn = true
                            // Carry state into range start if screen was already on.
                            screenOnAt = startTime
                        }
                    }

                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        if (isScreenOn) {
                            isScreenOn = false
                            screenOnAt = null
                        }
                    }
                }
                continue
            }

            if (ts > endTime) {
                break
            }

            when (event.eventType) {
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    // Fix #2: duplicate ON event is ignored.
                    if (!isScreenOn) {
                        isScreenOn = true
                        screenOnAt = ts
                    }
                }

                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    // Fix #2: duplicate OFF event is ignored.
                    if (isScreenOn) {
                        val startedAt = screenOnAt ?: startTime
                        if (ts > startedAt) {
                            totalScreenTime += ts - startedAt
                            lateNightUsage += overlapDuration(startedAt, ts, lateNightStart, lateNightEnd)
                        }
                        isScreenOn = false
                        screenOnAt = null
                    }
                }
            }
        }

        // Edge case: ON without OFF in range -> close at endTime.
        if (isScreenOn) {
            val startedAt = (screenOnAt ?: startTime).coerceAtMost(endTime)
            if (endTime > startedAt) {
                totalScreenTime += endTime - startedAt
                lateNightUsage += overlapDuration(startedAt, endTime, lateNightStart, lateNightEnd)
            }
        }

        return ScreenMetrics(
            screenTime = totalScreenTime,
            lateNightUsage = lateNightUsage,
        )
    }

    private fun overlapDuration(startA: Long, endA: Long, startB: Long, endB: Long): Long {
        val start = max(startA, startB)
        val end = min(endA, endB)
        return if (end > start) end - start else 0L
    }

    private data class ScreenMetrics(
        val screenTime: Long,
        val lateNightUsage: Long,
    )

    companion object {
        private const val INITIAL_STATE_BUFFER_MS = 60L * 60L * 1000L
        private const val LATE_NIGHT_HOURS_MS = 5L * 60L * 60L * 1000L
    }
}
