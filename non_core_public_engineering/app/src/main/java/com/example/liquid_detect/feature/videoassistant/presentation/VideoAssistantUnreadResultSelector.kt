package com.example.liquid_detect.feature.videoassistant.presentation

import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryEntry
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryStatus

internal object VideoAssistantUnreadResultSelector {
    fun select(entries: List<VideoAssistantHistoryEntry>): VideoAssistantHistoryEntry? {
        return entries
            .asSequence()
            .filter(::isUnreadCompletedResult)
            .maxByOrNull { it.updatedAtMs }
    }

    private fun isUnreadCompletedResult(entry: VideoAssistantHistoryEntry): Boolean {
        if (entry.reportViewed) return false
        return when (entry.status) {
            VideoAssistantHistoryStatus.AnalysisReady -> entry.hasAnalysis
            VideoAssistantHistoryStatus.ReplayOnly -> entry.hasReplay
            else -> false
        }
    }
}
