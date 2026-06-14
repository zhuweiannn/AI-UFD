package com.example.liquid_detect.media.playback

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import androidx.core.content.ContextCompat
import com.example.liquid_detect.R
import kotlin.math.max
import kotlin.math.min

class ShellPlaybackSeekBar @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {
    interface OnSeekChangeListener {
        fun onProgressChanged(seekBar: ShellPlaybackSeekBar, progress: Int, fromUser: Boolean)
        fun onStartTrackingTouch(seekBar: ShellPlaybackSeekBar)
        fun onStopTrackingTouch(seekBar: ShellPlaybackSeekBar)
    }

    private val density = resources.displayMetrics.density
    private val trackHeightPx = 4f * density
    private val thumbRadiusPx = 8f * density
    private val touchRadiusPx = 18f * density
    private val trackPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ContextCompat.getColor(context, R.color.shell_card_border)
            style = Paint.Style.FILL
        }
    private val progressPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ContextCompat.getColor(context, R.color.shell_accent)
            style = Paint.Style.FILL
        }
    private val thumbPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ContextCompat.getColor(context, R.color.shell_text_primary)
            style = Paint.Style.FILL
        }
    private val thumbStrokePaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ContextCompat.getColor(context, R.color.shell_bg)
            style = Paint.Style.STROKE
            strokeWidth = 2f * density
        }
    private var listener: OnSeekChangeListener? = null
    private var userTracking = false

    var max: Int = 1000
        set(value) {
            field = value.coerceAtLeast(1)
            progress = progress
            invalidate()
        }

    var progress: Int = 0
        set(value) {
            val normalized = value.coerceIn(0, max)
            if (field == normalized) return
            field = normalized
            invalidate()
            listener?.onProgressChanged(this, normalized, userTracking)
        }

    fun setOnSeekChangeListener(listener: OnSeekChangeListener?) {
        this.listener = listener
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val desiredHeight = (touchRadiusPx * 2 + paddingTop + paddingBottom).toInt()
        val measuredHeight = resolveSize(desiredHeight, heightMeasureSpec)
        setMeasuredDimension(MeasureSpec.getSize(widthMeasureSpec), measuredHeight)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val trackLeft = paddingLeft + thumbRadiusPx
        val trackRight = width - paddingRight - thumbRadiusPx
        if (trackRight <= trackLeft) return
        val centerY = height / 2f
        val progressX = positionToX(progress)
        canvas.drawRoundRect(trackLeft, centerY - trackHeightPx / 2f, trackRight, centerY + trackHeightPx / 2f, trackHeightPx, trackHeightPx, trackPaint)
        canvas.drawRoundRect(trackLeft, centerY - trackHeightPx / 2f, progressX, centerY + trackHeightPx / 2f, trackHeightPx, trackHeightPx, progressPaint)
        canvas.drawCircle(progressX, centerY, thumbRadiusPx, thumbPaint)
        canvas.drawCircle(progressX, centerY, thumbRadiusPx, thumbStrokePaint)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!isEnabled) return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                parent?.requestDisallowInterceptTouchEvent(true)
                userTracking = true
                updateProgressFromTouch(event.x, fromUser = true)
                listener?.onStartTrackingTouch(this)
                isPressed = true
                return true
            }

            MotionEvent.ACTION_MOVE -> {
                updateProgressFromTouch(event.x, fromUser = true)
                return true
            }

            MotionEvent.ACTION_UP -> {
                updateProgressFromTouch(event.x, fromUser = true)
                if (userTracking) {
                    listener?.onStopTrackingTouch(this)
                }
                userTracking = false
                isPressed = false
                performClick()
                return true
            }

            MotionEvent.ACTION_CANCEL -> {
                if (userTracking) {
                    listener?.onStopTrackingTouch(this)
                }
                userTracking = false
                isPressed = false
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    override fun performClick(): Boolean = super.performClick()

    private fun updateProgressFromTouch(x: Float, fromUser: Boolean) {
        val trackLeft = paddingLeft + thumbRadiusPx
        val trackRight = width - paddingRight - thumbRadiusPx
        val clampedX = min(max(x, trackLeft), trackRight)
        val fraction = if (trackRight > trackLeft) (clampedX - trackLeft) / (trackRight - trackLeft) else 0f
        val newProgress = (fraction * max).toInt().coerceIn(0, max)
        if (progress != newProgress) {
            progress = newProgress
        } else if (fromUser) {
            listener?.onProgressChanged(this, newProgress, true)
        }
    }

    private fun positionToX(progress: Int): Float {
        val trackLeft = paddingLeft + thumbRadiusPx
        val trackRight = width - paddingRight - thumbRadiusPx
        if (trackRight <= trackLeft) return trackLeft
        return trackLeft + (progress / max.toFloat()) * (trackRight - trackLeft)
    }
}
