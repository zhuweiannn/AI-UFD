package com.example.liquid_detect.feature.camera

internal enum class CameraFpsTarget(
    val value: Int,
    val label: String,
) {
    FPS_30(30, "30fps"),
    FPS_60(60, "60fps"),
    ;

    companion object {
        fun fromValue(value: Int): CameraFpsTarget = entries.firstOrNull { it.value == value } ?: FPS_30
    }
}

internal data class CameraCaptureProfileOption(
    val width: Int,
    val height: Int,
    val supportedFpsTargets: Set<CameraFpsTarget>,
    val knownUnsupportedFpsTargets: Set<CameraFpsTarget> = emptySet(),
) {
    val key: String = "${width}x$height"
    val label: String = "${width}×${height}"

    fun supports(target: CameraFpsTarget): Boolean {
        return target == CameraFpsTarget.FPS_30 || supportedFpsTargets.contains(target)
    }

    fun canRequest(target: CameraFpsTarget): Boolean {
        return supports(target)
    }

    fun isKnownUnsupported(target: CameraFpsTarget): Boolean {
        return !supportedFpsTargets.contains(target) && knownUnsupportedFpsTargets.contains(target)
    }
}

internal data class CameraCaptureProfileSelection(
    val options: List<CameraCaptureProfileOption>,
    val selectedProfile: CameraCaptureProfileOption?,
    val selectedFpsTarget: CameraFpsTarget,
    val canRequest60Fps: Boolean,
)

internal data class AppliedCameraCaptureProfile(
    val width: Int,
    val height: Int,
    val fpsTarget: CameraFpsTarget,
) {
    val resolutionLabel: String = "${width}×${height}"
    val profileLabel: String = "${width}×${height} · ${fpsTarget.label}"
}
