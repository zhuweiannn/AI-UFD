package com.example.liquid_detect.feature.videoassistant.presentation

import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryEntry

internal sealed interface VideoAssistantUnfinishedConflictDecision {
    data object None : VideoAssistantUnfinishedConflictDecision
    data object ResumeExisting : VideoAssistantUnfinishedConflictDecision
    data class ShowConflict(
        val unfinishedEntry: VideoAssistantHistoryEntry,
    ) : VideoAssistantUnfinishedConflictDecision
}

internal object VideoAssistantUnfinishedConflictResolver {
    fun resolve(
        selectedSourceFingerprint: String?,
        unfinishedEntry: VideoAssistantHistoryEntry?,
    ): VideoAssistantUnfinishedConflictDecision {
        if (selectedSourceFingerprint.isNullOrBlank() || unfinishedEntry == null) {
            return VideoAssistantUnfinishedConflictDecision.None
        }
        return if (unfinishedEntry.sourceFingerprint == selectedSourceFingerprint) {
            VideoAssistantUnfinishedConflictDecision.ResumeExisting
        } else {
            VideoAssistantUnfinishedConflictDecision.ShowConflict(unfinishedEntry)
        }
    }
}
