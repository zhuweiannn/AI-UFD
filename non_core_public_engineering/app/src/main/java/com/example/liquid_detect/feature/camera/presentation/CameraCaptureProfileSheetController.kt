package com.example.liquid_detect.feature.camera.presentation

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.RadioButton
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.liquid_detect.R
import com.example.liquid_detect.feature.camera.CameraFpsTarget
import com.google.android.material.bottomsheet.BottomSheetDialog

internal data class CameraCaptureFpsOptionUi(
    val target: CameraFpsTarget,
    val enabled: Boolean,
)

internal data class CameraCaptureProfileResolutionItemUi(
    val key: String,
    val title: String,
    val subtitle: String?,
    val selected: Boolean,
    val enabled: Boolean,
)

internal data class CameraCaptureProfileSheetUi(
    val selectedFpsTarget: CameraFpsTarget,
    val fpsOptions: List<CameraCaptureFpsOptionUi>,
    val resolutionItems: List<CameraCaptureProfileResolutionItemUi>,
)

internal interface CameraCaptureProfileSheetCallbacks {
    fun onFpsSelected(target: CameraFpsTarget)

    fun onResolutionSelected(profileKey: String)
}

internal class CameraCaptureProfileSheetController(
    private val context: Context,
    private val layoutInflater: LayoutInflater,
) {
    private var dialog: BottomSheetDialog? = null
    private var resolutionAdapter: CameraCaptureProfileResolutionAdapter? = null
    private var radio30: RadioButton? = null
    private var radio60: RadioButton? = null

    fun toggle(
        anchor: View,
        stateProvider: () -> CameraCaptureProfileSheetUi,
        callbacks: CameraCaptureProfileSheetCallbacks,
    ) {
        if (dialog?.isShowing == true) {
            dismiss()
            return
        }
        show(anchor, stateProvider, callbacks)
    }

    fun dismiss() {
        dialog?.dismiss()
        dialog = null
        resolutionAdapter = null
        radio30 = null
        radio60 = null
    }

    private fun show(
        anchor: View,
        stateProvider: () -> CameraCaptureProfileSheetUi,
        callbacks: CameraCaptureProfileSheetCallbacks,
    ) {
        val popupView = layoutInflater.inflate(R.layout.popup_camera_capture_profile, null)
        val adapter =
            CameraCaptureProfileResolutionAdapter { item ->
                if (!item.enabled) return@CameraCaptureProfileResolutionAdapter
                callbacks.onResolutionSelected(item.key)
                dismiss()
            }
        popupView.findViewById<RecyclerView>(R.id.listCaptureProfiles).apply {
            layoutManager = LinearLayoutManager(context)
            this.adapter = adapter
        }
        popupView.findViewById<RadioButton>(R.id.radioCaptureFps30).also { button ->
            radio30 = button
            button.setOnClickListener {
                if (!button.isEnabled) return@setOnClickListener
                callbacks.onFpsSelected(CameraFpsTarget.FPS_30)
                render(stateProvider())
            }
        }
        popupView.findViewById<RadioButton>(R.id.radioCaptureFps60).also { button ->
            radio60 = button
            button.setOnClickListener {
                if (!button.isEnabled) return@setOnClickListener
                callbacks.onFpsSelected(CameraFpsTarget.FPS_60)
                render(stateProvider())
            }
        }

        val bottomSheetDialog =
            BottomSheetDialog(context).apply {
                setContentView(popupView)
                setOnDismissListener {
                    dialog = null
                    resolutionAdapter = null
                    radio30 = null
                    radio60 = null
                }
                setOnShowListener {
                    findViewById<FrameLayout>(com.google.android.material.R.id.design_bottom_sheet)?.setBackgroundResource(android.R.color.transparent)
                }
            }

        dialog = bottomSheetDialog
        resolutionAdapter = adapter
        render(stateProvider())
        bottomSheetDialog.show()
    }

    private fun render(state: CameraCaptureProfileSheetUi) {
        radio30?.apply {
            val enabled = state.fpsOptions.firstOrNull { it.target == CameraFpsTarget.FPS_30 }?.enabled == true
            isEnabled = enabled
            alpha = if (enabled) 1f else 0.42f
            isChecked = state.selectedFpsTarget == CameraFpsTarget.FPS_30
        }
        radio60?.apply {
            val enabled = state.fpsOptions.firstOrNull { it.target == CameraFpsTarget.FPS_60 }?.enabled == true
            isEnabled = enabled
            alpha = if (enabled) 1f else 0.42f
            isChecked = state.selectedFpsTarget == CameraFpsTarget.FPS_60
        }
        resolutionAdapter?.submitList(state.resolutionItems)
    }
}
