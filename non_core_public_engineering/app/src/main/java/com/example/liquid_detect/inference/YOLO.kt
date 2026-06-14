package com.example.liquid_detect.inference

import android.content.res.AssetManager
import android.view.Surface

interface OnDetectionsListener {
    // rects: [x0,y0,w0,h0, x1,y1,w1,h1, ...] in pixels, aligned with rgb.cols/rows
    fun onDetections(tsNanos: Long, imgW: Int, imgH: Int,
                     rects: FloatArray, confs: FloatArray, clsIds: IntArray)
}

interface OnFrameListener {
    // NV21 frame rotated to display orientation (w x h), timestamp in ns
    fun onFrame(nv21: ByteArray, width: Int, height: Int, rotationDeg: Int, timestampNs: Long)
}

interface OnRenderResultsListener {
    fun onRenderResults(
        tsNanos: Long,
        imgW: Int,
        imgH: Int,
        rects: FloatArray,
        confs: FloatArray,
        clsIds: IntArray,
        contourSizes: IntArray,
        contourPoints: FloatArray,
    )
}

class YOLO {
    // Public shell keeps the Kotlin/JNI contract; native implementation is omitted.
    @Volatile
    private var lastLoadedModel: LoadedModelKey? = null

    @Synchronized
    fun loadModel(
        mgr: AssetManager?,
        task: String,
        modelBasename: String,
        targetSize: Int,
        cpugpu: Int,
    ): Boolean {
        val key = LoadedModelKey(task, modelBasename, targetSize, cpugpu)
        if (lastLoadedModel == key) return true
        val ok = nativeLoadModel(mgr, task, modelBasename, targetSize, cpugpu)
        if (ok) {
            lastLoadedModel = key
        }
        return ok
    }

    // ... native model loading implementation omitted from this public shell.
    private external fun nativeLoadModel(
        mgr: AssetManager?,
        task: String,
        modelBasename: String,
        targetSize: Int,
        cpugpu: Int,
    ): Boolean

    external fun openCamera(facing: Int): Boolean

    external fun closeCamera(): Boolean

    external fun setOutputWindow(surface: Surface?): Boolean

    external fun clearLastOutputFrameCache(): Boolean

//    external fun setRecordingSurface(surface: Surface?): Boolean
//
//    /** 0 = camera stream, 1 = video file */
//    external fun setSourceMode(mode: Int)

    // Send a NV21 frame (w x h) into native for processing and rendering
    external fun processNV21Frame(nv21: ByteArray, width: Int, height: Int, ptsNs: Long, rotateDeg: Int): Boolean

    // File-mode preview rendering cadence. 1 means render every frame, N means render every Nth frame.
    external fun setFilePreviewRenderCadence(renderEveryNFrames: Int): Boolean

    // File-mode preview-only render budget. 0 means no extra time throttle, otherwise render at most once per interval.
    external fun setFilePreviewRenderIntervalMs(intervalMs: Int): Boolean

    // Register/unregister detection callback
    external fun setDetectionsListener(listener: OnDetectionsListener?)

    // Register/unregister render callback carrying replay/local overlay contours.
    external fun setRenderResultsListener(listener: OnRenderResultsListener?)

    // Register/unregister NV21 frame callback for recording
    external fun setFrameListener(listener: OnFrameListener?)

    // Camera resolution queries and control
    external fun listSupportedResolutions(facing: Int): IntArray
    external fun setPreferredCaptureProfile(width: Int, height: Int, targetFps: Int): Boolean
    external fun getAppliedCaptureProfile(): IntArray
    external fun getAppliedRecordingProfile(): IntArray
    external fun setCameraPreviewInferenceEnabled(enabled: Boolean): Boolean
    external fun setCameraPreviewInferenceIntervalMs(intervalMs: Int): Boolean

    // Recording controls (camera mode only)
    external fun startRecording(outputFd: Int): Boolean
    external fun stopRecording(): Boolean

    companion object {
        init {
            System.loadLibrary("yolo")
        }
    }

    private data class LoadedModelKey(
        val task: String,
        val modelBasename: String,
        val targetSize: Int,
        val cpugpu: Int,
    )
}
