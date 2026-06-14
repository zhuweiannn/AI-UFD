package com.example.liquid_detect.media

internal class VideoDecodeUiProgressThrottler(
    private val minIntervalMs: Long = 220L,
) {
    private var lastDispatchElapsedMs = Long.MIN_VALUE

    fun reset() {
        lastDispatchElapsedMs = Long.MIN_VALUE
    }

    fun shouldDispatch(
        progress: VideoDecodeProgress,
        force: Boolean,
    ): Boolean {
        if (force) {
            lastDispatchElapsedMs = progress.elapsedMs
            return true
        }
        if (lastDispatchElapsedMs == Long.MIN_VALUE) {
            lastDispatchElapsedMs = progress.elapsedMs
            return true
        }
        if (progress.elapsedMs - lastDispatchElapsedMs < minIntervalMs) {
            return false
        }
        lastDispatchElapsedMs = progress.elapsedMs
        return true
    }
}
