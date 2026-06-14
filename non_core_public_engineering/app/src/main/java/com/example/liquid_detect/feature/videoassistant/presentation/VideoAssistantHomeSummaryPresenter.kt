package com.example.liquid_detect.feature.videoassistant.presentation

import com.example.liquid_detect.feature.videoassistant.VideoAssistantPhase
import com.example.liquid_detect.feature.videoassistant.formatClock
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryEntry
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryStatus
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantProcessingSessionState

internal data class VideoAssistantHomeSummaryUi(
    val statusText: String,
    val detailText: String,
    val progressPermille: Int = 0,
    val showProgress: Boolean,
)

internal object VideoAssistantHomeSummaryPresenter {
    fun build(state: VideoAssistantProcessingSessionState): VideoAssistantHomeSummaryUi? {
        return when (state.phase) {
            VideoAssistantPhase.Processing ->
                VideoAssistantHomeSummaryUi(
                    statusText = "后台处理中",
                    detailText =
                        "${state.progress.progressPercent}% · ${state.progress.processedFrames}/${state.progress.totalFrames} · 预计剩余 ${formatClock(state.progress.estimatedRemainingMs)}",
                    progressPermille = state.progress.progressPermille,
                    showProgress = true,
                )

            VideoAssistantPhase.Paused ->
                VideoAssistantHomeSummaryUi(
                    statusText = "已暂停",
                    detailText =
                        "${state.progress.progressPercent}% · ${state.progress.processedFrames}/${state.progress.totalFrames} · 预计剩余 ${formatClock(state.progress.estimatedRemainingMs)}",
                    progressPermille = state.progress.progressPermille,
                    showProgress = true,
                )

            VideoAssistantPhase.FinishingAnalysis ->
                VideoAssistantHomeSummaryUi(
                    statusText = "正在收尾",
                    detailText =
                        "帧进度 ${state.progress.processedFrames}/${state.progress.totalFrames} · 预计剩余 ${formatClock(state.progress.estimatedRemainingMs)}",
                    progressPermille = state.progress.progressPermille.coerceAtLeast(900),
                    showProgress = true,
                )

            else -> latestUnreadReport(state.historyEntries)
        }
    }

    private fun latestUnreadReport(entries: List<VideoAssistantHistoryEntry>): VideoAssistantHomeSummaryUi? {
        val entry = VideoAssistantUnreadResultSelector.select(entries) ?: return null
        return when (entry.status) {
            VideoAssistantHistoryStatus.AnalysisReady ->
                VideoAssistantHomeSummaryUi(
                    statusText = "新报告待查看",
                    detailText = "${entry.displayName} · 报告已就绪",
                    showProgress = false,
                )

            VideoAssistantHistoryStatus.ReplayOnly ->
                VideoAssistantHomeSummaryUi(
                    statusText = "新结果待查看",
                    detailText = "${entry.displayName} · 分析失败",
                    showProgress = false,
                )

            else -> null
        }
    }
}
