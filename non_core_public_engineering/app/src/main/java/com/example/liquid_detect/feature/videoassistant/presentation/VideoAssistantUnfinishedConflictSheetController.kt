package com.example.liquid_detect.feature.videoassistant.presentation

import android.content.Context
import android.view.LayoutInflater
import androidx.core.content.ContextCompat
import com.example.liquid_detect.R
import com.example.liquid_detect.databinding.SheetVideoAssistantUnfinishedConflictBinding
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantHistoryEntry
import com.google.android.material.bottomsheet.BottomSheetDialog

internal class VideoAssistantUnfinishedConflictSheetController(
    private val context: Context,
    private val layoutInflater: LayoutInflater,
) {
    private var dialog: BottomSheetDialog? = null

    fun show(
        unfinishedEntry: VideoAssistantHistoryEntry,
        onReturnToUnfinished: () -> Unit,
        onDeleteAndStartCurrent: () -> Unit,
    ) {
        dismiss()
        val binding = SheetVideoAssistantUnfinishedConflictBinding.inflate(layoutInflater)
        binding.textConflictMessage.text =
            context.getString(
                R.string.unfinished_conflict_message,
                unfinishedEntry.displayName,
            )
        val bottomSheetDialog =
            BottomSheetDialog(context).apply {
                setContentView(binding.root)
                behavior.skipCollapsed = true
                window?.setBackgroundDrawable(ContextCompat.getDrawable(context, android.R.color.transparent))
                setOnDismissListener { dialog = null }
            }
        binding.buttonReturnToUnfinished.setOnClickListener {
            onReturnToUnfinished()
            bottomSheetDialog.dismiss()
        }
        binding.buttonDeleteAndStartCurrent.setOnClickListener {
            onDeleteAndStartCurrent()
            bottomSheetDialog.dismiss()
        }
        binding.buttonCancelConflict.setOnClickListener {
            bottomSheetDialog.dismiss()
        }
        dialog = bottomSheetDialog
        bottomSheetDialog.show()
    }

    fun dismiss() {
        dialog?.dismiss()
        dialog = null
    }
}
