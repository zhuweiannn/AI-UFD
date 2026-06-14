package com.example.liquid_detect.ui.workflow

internal enum class WorkflowHomeEntryPoint {
    VideoAssistantCard,
    VideoAssistantButton,
    CameraCaptureCard,
    CameraCaptureButton,
}

internal sealed interface WorkflowHomeAction {
    data object OpenVideoAssistant : WorkflowHomeAction

    data object OpenCameraCapture : WorkflowHomeAction

    data object RequestCameraPermission : WorkflowHomeAction

    data object ShowCameraPermissionDenied : WorkflowHomeAction
}

internal object WorkflowHomeActionResolver {
    fun resolveTap(
        entryPoint: WorkflowHomeEntryPoint,
        hasCameraPermission: Boolean,
    ): WorkflowHomeAction {
        return when (entryPoint) {
            WorkflowHomeEntryPoint.VideoAssistantCard,
            WorkflowHomeEntryPoint.VideoAssistantButton,
            -> WorkflowHomeAction.OpenVideoAssistant

            WorkflowHomeEntryPoint.CameraCaptureCard,
            WorkflowHomeEntryPoint.CameraCaptureButton,
            -> {
                if (hasCameraPermission) {
                    WorkflowHomeAction.OpenCameraCapture
                } else {
                    WorkflowHomeAction.RequestCameraPermission
                }
            }
        }
    }

    fun resolveCameraPermissionResult(granted: Boolean): WorkflowHomeAction {
        return if (granted) {
            WorkflowHomeAction.OpenCameraCapture
        } else {
            WorkflowHomeAction.ShowCameraPermissionDenied
        }
    }
}
