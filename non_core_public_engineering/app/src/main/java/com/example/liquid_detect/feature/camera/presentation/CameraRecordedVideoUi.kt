package com.example.liquid_detect.feature.camera.presentation

import com.example.liquid_detect.feature.camera.session.CameraRecordedVideoEntry
import com.example.liquid_detect.feature.camera.session.CameraRecordedVideoStatus
import com.example.liquid_detect.feature.videoassistant.formatBytes
import com.example.liquid_detect.feature.videoassistant.formatClock

internal enum class CameraRecordedVideoBadgeTone {
    Success,
    Secondary,
}

internal data class CameraRecordedVideoBadgeUi(
    val text: String,
    val tone: CameraRecordedVideoBadgeTone,
)

internal data class CameraRecordedVideoListItemUi(
    val entry: CameraRecordedVideoEntry,
    val titleText: String,
    val statusText: String,
    val detailText: String,
    val badge: CameraRecordedVideoBadgeUi,
    val showDeleteAction: Boolean,
)

internal object CameraRecordedVideoListItemFactory {
    fun build(entries: List<CameraRecordedVideoEntry>): List<CameraRecordedVideoListItemUi> {
        return entries.sortedByDescending { it.updatedAtMs }.map(::buildItem)
    }

    private fun buildItem(entry: CameraRecordedVideoEntry): CameraRecordedVideoListItemUi {
        return CameraRecordedVideoListItemUi(
            entry = entry,
            titleText = entry.metadata.displayName,
            statusText =
                when (entry.status) {
                    CameraRecordedVideoStatus.AnalysisReady -> "分析结果就绪"
                    CameraRecordedVideoStatus.ReplayOnly -> "分析失败"
                    CameraRecordedVideoStatus.Unprocessed -> "未处理"
                },
            detailText = buildMetadataLine(entry),
            badge =
                when (entry.status) {
                    CameraRecordedVideoStatus.AnalysisReady ->
                        CameraRecordedVideoBadgeUi("分析完成", CameraRecordedVideoBadgeTone.Success)
                    CameraRecordedVideoStatus.ReplayOnly ->
                        CameraRecordedVideoBadgeUi("分析失败", CameraRecordedVideoBadgeTone.Secondary)
                    CameraRecordedVideoStatus.Unprocessed ->
                        CameraRecordedVideoBadgeUi("未处理", CameraRecordedVideoBadgeTone.Secondary)
                },
            showDeleteAction = true,
        )
    }

    private fun buildMetadataLine(entry: CameraRecordedVideoEntry): String {
        val metadata = entry.metadata
        val durationText = formatClock(metadata.durationMs)
        val sizeText = formatBytes(metadata.sizeBytes)
        val resolutionText =
            if (metadata.width > 0 && metadata.height > 0) {
                "${metadata.width}×${metadata.height}"
            } else {
                "—"
            }
        return "$durationText · $sizeText · $resolutionText"
    }
}
