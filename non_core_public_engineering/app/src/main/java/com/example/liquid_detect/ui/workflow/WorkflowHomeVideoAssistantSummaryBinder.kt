package com.example.liquid_detect.ui.workflow

import android.view.View
import android.widget.ProgressBar
import android.widget.TextView
import com.example.liquid_detect.feature.videoassistant.presentation.VideoAssistantHomeSummaryPresenter
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantProcessingSessionState

internal class WorkflowHomeVideoAssistantSummaryBinder(
    private val summaryGroup: View,
    private val statusView: TextView,
    private val progressView: ProgressBar,
    private val detailView: TextView,
) {
    fun bind(state: VideoAssistantProcessingSessionState) {
        val summary = VideoAssistantHomeSummaryPresenter.build(state)
        summaryGroup.visibility = if (summary != null) View.VISIBLE else View.GONE
        if (summary == null) {
            statusView.text = ""
            progressView.visibility = View.GONE
            progressView.progress = 0
            detailView.text = ""
            return
        }

        statusView.text = summary.statusText
        progressView.visibility = if (summary.showProgress) View.VISIBLE else View.GONE
        progressView.progress = summary.progressPermille
        detailView.text = summary.detailText
    }
}
