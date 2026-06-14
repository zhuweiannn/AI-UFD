package com.example.liquid_detect.platform.logging

import android.util.Log

/**
 * 轻量的结构化日志工具，统一输出关键事件，便于后续替换成更完整的可观测性方案。
 */
object CaptureLogger {
    private const val TAG = "Capture"

    fun event(name: String, detail: String? = null) {
        Log.i(TAG, format("EVENT", name, detail))
    }

    fun warn(name: String, detail: String? = null, error: Throwable? = null) {
        Log.w(TAG, format("WARN", name, detail), error)
    }

    fun error(name: String, detail: String? = null, error: Throwable? = null) {
        Log.e(TAG, format("ERROR", name, detail), error)
    }

    private fun format(level: String, name: String, detail: String?): String {
        return buildString {
            append('[').append(level).append("] ").append(name)
            if (!detail.isNullOrBlank()) {
                append(" :: ").append(detail)
            }
        }
    }
}
