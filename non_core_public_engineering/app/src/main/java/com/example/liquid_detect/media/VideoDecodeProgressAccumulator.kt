package com.example.liquid_detect.media

internal class VideoDecodeProgressAccumulator {
    private var elapsedBeforeCurrentRunMs: Long = 0L
    private var activeRunStartedAtMs: Long? = null

    fun start(nowMs: Long, resetSessionMetrics: Boolean) {
        if (resetSessionMetrics) {
            elapsedBeforeCurrentRunMs = 0L
        }
        activeRunStartedAtMs = nowMs
    }

    fun pause(nowMs: Long) {
        val runStartedAtMs = activeRunStartedAtMs ?: return
        elapsedBeforeCurrentRunMs += (nowMs - runStartedAtMs).coerceAtLeast(0L)
        activeRunStartedAtMs = null
    }

    fun currentElapsedMs(nowMs: Long): Long {
        val activeContribution =
            activeRunStartedAtMs?.let { (nowMs - it).coerceAtLeast(0L) } ?: 0L
        return elapsedBeforeCurrentRunMs + activeContribution
    }

    fun reset() {
        elapsedBeforeCurrentRunMs = 0L
        activeRunStartedAtMs = null
    }

    fun estimateProcessedFrames(
        processedUs: Long,
        durationUs: Long,
        estimatedTotalFrames: Int,
    ): Int {
        if (durationUs <= 0L || estimatedTotalFrames <= 0) return 0
        val normalizedProgress = processedUs.coerceIn(0L, durationUs)
        return ((normalizedProgress.toDouble() / durationUs.toDouble()) * estimatedTotalFrames)
            .toInt()
            .coerceIn(0, estimatedTotalFrames)
    }
}
