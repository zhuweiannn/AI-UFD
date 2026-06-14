package com.example.liquid_detect.feature.videoassistant

import android.net.Uri
import com.example.liquid_detect.feature.videoassistant.session.RecoverableVideoSession

enum class VideoAssistantPhase {
    NoSelection,
    Ready,
    Processing,
    Paused,
    FinishingAnalysis,
    Completed,
    Error,
}

enum class VideoAssistantEntryStage {
    ChooseVideo,
    ReadyToStart,
    Recoverable,
}

data class VideoFileMetadata(
    val displayName: String,
    val sizeBytes: Long,
    val durationMs: Long,
    val width: Int,
    val height: Int,
    val frameRate: Float,
    val frameCountEstimate: Int,
)

data class ProcessingProgress(
    val progressPercent: Int = 0,
    val progressPermille: Int = 0,
    val processedFrames: Int = 0,
    val totalFrames: Int = 0,
    val estimatedRemainingMs: Long = 0L,
)

data class RecoverableSessionUi(
    val session: RecoverableVideoSession,
)

sealed interface VideoAssistantAction {
    data object StartProcessing : VideoAssistantAction
    data object PauseProcessing : VideoAssistantAction
    data object ResumeProcessing : VideoAssistantAction
    data object CancelProcessing : VideoAssistantAction
    data object FinishProcessing : VideoAssistantAction
    data object FinishAnalysis : VideoAssistantAction
    data object FailAnalysis : VideoAssistantAction
    data object FailProcessing : VideoAssistantAction
    data object ResetError : VideoAssistantAction
}

internal data class VideoAssistantUiState(
    val phase: VideoAssistantPhase = VideoAssistantPhase.NoSelection,
    val entryStage: VideoAssistantEntryStage = VideoAssistantEntryStage.ChooseVideo,
    val selectedVideoUri: Uri? = null,
    val metadata: VideoFileMetadata? = null,
    val progress: ProcessingProgress = ProcessingProgress(),
    val previewLoading: Boolean = false,
    val statusText: String = "",
    val errorText: String? = null,
    val hasReplay: Boolean = false,
    val hasAnalysis: Boolean = false,
    val hasLiveAnalysis: Boolean = false,
    val analysisWarning: String? = null,
    val recoverableSession: RecoverableSessionUi? = null,
    val recoveryLoading: Boolean = false,
    val recoveryProgressPercent: Int = 0,
    val showLiveProcessingCurves: Boolean = false,
    val historyItems: List<VideoAssistantHistoryListItemUi> = emptyList(),
)

class VideoAssistantStateMachine {
    fun transition(
        current: VideoAssistantPhase,
        action: VideoAssistantAction,
        hasSelection: Boolean,
    ): VideoAssistantPhase {
        // ... workflow transition implementation omitted from public package.
        return current
    }
}
