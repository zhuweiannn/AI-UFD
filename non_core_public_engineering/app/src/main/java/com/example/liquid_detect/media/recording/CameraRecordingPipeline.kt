package com.example.liquid_detect.media.recording

sealed interface FrameData {
    // ... implementation omitted from public package.
}

fun interface EncoderBackendFactory {
    // ... contract details omitted from public package.
}
interface EncoderBackend {
    // ... contract details omitted from public package.
}

class CameraRecordingPipeline {
    // ... implementation omitted from public package.
}

class RecordingSession {
    // ... implementation omitted from public package.
}

class MediaCodecEncoderBackend {
    // ... implementation omitted from public package.
}
