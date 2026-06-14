package com.example.liquid_detect.media

import android.content.Context
import android.media.MediaMetadataRetriever
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import com.example.liquid_detect.feature.videoassistant.VideoFileMetadata

object VideoMetadataReader {
    fun read(context: Context, uri: Uri): VideoFileMetadata {
        val fileInfo = queryFileInfo(context, uri)
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            val rawWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            val rawHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            val rotationDegrees =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val swapDimensions = rotationDegrees == 90 || rotationDegrees == 270
            val width = if (swapDimensions) rawHeight else rawWidth
            val height = if (swapDimensions) rawWidth else rawHeight
            val frameRate = readFrameRate(context, uri)
            val frameCountEstimate = readFrameCount(retriever, durationMs, frameRate)
            VideoFileMetadata(
                displayName = fileInfo.first,
                sizeBytes = fileInfo.second,
                durationMs = durationMs,
                width = width,
                height = height,
                frameRate = frameRate,
                frameCountEstimate = frameCountEstimate,
            )
        } finally {
            retriever.release()
        }
    }

    private fun queryFileInfo(context: Context, uri: Uri): Pair<String, Long> {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val name = cursor.getString(0) ?: uri.lastPathSegment ?: "未命名视频"
                    val size = if (cursor.isNull(1)) 0L else cursor.getLong(1)
                    return name to size
                }
            }
        return (uri.lastPathSegment ?: "未命名视频") to 0L
    }

    private fun readFrameRate(context: Context, uri: Uri): Float {
        val extractor = MediaExtractor()
        return try {
            context.contentResolver.openFileDescriptor(uri, "r").use { pfd ->
                extractor.setDataSource(requireNotNull(pfd).fileDescriptor)
            }
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/")) continue
                return try {
                    format.getInteger(MediaFormat.KEY_FRAME_RATE).toFloat().coerceAtLeast(1f)
                } catch (_: Throwable) {
                    30f
                }
            }
            30f
        } finally {
            extractor.release()
        }
    }

    private fun readFrameCount(
        retriever: MediaMetadataRetriever,
        durationMs: Long,
        frameRate: Float,
    ): Int {
        val apiFrameCount =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT)?.toIntOrNull()
            } else {
                null
            }
        return apiFrameCount?.takeIf { it > 0 }
            ?: ((durationMs / 1000f) * frameRate).toInt().coerceAtLeast(1)
    }
}
