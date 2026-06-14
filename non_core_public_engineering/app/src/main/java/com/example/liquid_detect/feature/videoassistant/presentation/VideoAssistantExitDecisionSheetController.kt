package com.example.liquid_detect.feature.videoassistant.presentation

import android.content.Context
import android.view.LayoutInflater
import androidx.core.content.ContextCompat
import com.example.liquid_detect.R
import com.example.liquid_detect.databinding.SheetVideoAssistantExitDecisionBinding
import com.google.android.material.bottomsheet.BottomSheetDialog

internal class VideoAssistantExitDecisionSheetController(
    private val context: Context,
    private val layoutInflater: LayoutInflater,
) {
    private var dialog: BottomSheetDialog? = null

    fun show(
        pauseAndReturnEnabled: Boolean,
        onPauseAndReturn: () -> Unit,
        onBackgroundHome: () -> Unit,
    ) {
        dismiss()
        val binding = SheetVideoAssistantExitDecisionBinding.inflate(layoutInflater)
        binding.buttonPauseAndChoose.text =
            context.getString(
                if (pauseAndReturnEnabled) {
                    R.string.processing_exit_pause_and_choose
                } else {
                    R.string.processing_exit_choose_only
                },
            )
        val bottomSheetDialog =
            BottomSheetDialog(context).apply {
                setContentView(binding.root)
                behavior.skipCollapsed = true
                window?.setBackgroundDrawable(ContextCompat.getDrawable(context, android.R.color.transparent))
                setOnDismissListener { dialog = null }
            }
        binding.buttonPauseAndChoose.setOnClickListener {
            onPauseAndReturn()
            bottomSheetDialog.dismiss()
        }
        binding.buttonBackgroundHome.setOnClickListener {
            onBackgroundHome()
            bottomSheetDialog.dismiss()
        }
        binding.buttonStay.setOnClickListener {
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
