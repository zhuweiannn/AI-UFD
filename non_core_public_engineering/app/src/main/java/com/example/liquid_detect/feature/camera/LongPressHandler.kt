package com.example.liquid_detect.feature.camera

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * 统一处理短按/长按（默认 3 秒）并暴露回调，便于测试与重用。
 */
class LongPressHandler(
    private val scope: CoroutineScope,
    private val longPressMillis: Long = 3_000L,
    private val onLongPress: () -> Unit,
    private val onShortPress: () -> Unit,
) {
    private var job: Job? = null
    private var longTriggered = false

    fun onPressDown() {
        longTriggered = false
        job?.cancel()
        job = scope.launch {
            delay(longPressMillis)
            longTriggered = true
            onLongPress()
        }
    }

    fun onPressUp() {
        val wasLong = longTriggered
        job?.cancel()
        job = null
        if (!wasLong) {
            onShortPress()
        }
    }
}
