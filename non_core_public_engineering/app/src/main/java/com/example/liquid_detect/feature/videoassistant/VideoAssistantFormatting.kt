package com.example.liquid_detect.feature.videoassistant

internal fun rotationIndexToDeg(index: Int): Int? {
    return when (index) {
        1 -> 0
        2 -> 90
        3 -> 180
        4 -> 270
        else -> null
    }
}

internal fun formatClock(durationMs: Long): String {
    val totalSeconds = (durationMs / 1000L).coerceAtLeast(0L)
    val minutes = totalSeconds / 60L
    val seconds = totalSeconds % 60L
    return "%02d:%02d".format(minutes, seconds)
}

internal fun formatPlaybackTime(positionMs: Long, durationMs: Long): String {
    return "${formatClock(positionMs)}/${formatClock(durationMs)}"
}

internal fun formatBytes(sizeBytes: Long): String {
    if (sizeBytes <= 0L) return "-"
    val kb = 1024f
    val mb = kb * 1024f
    val gb = mb * 1024f
    return when {
        sizeBytes >= gb -> String.format("%.2f GB", sizeBytes / gb)
        sizeBytes >= mb -> String.format("%.1f MB", sizeBytes / mb)
        sizeBytes >= kb -> String.format("%.1f KB", sizeBytes / kb)
        else -> "$sizeBytes B"
    }
}
