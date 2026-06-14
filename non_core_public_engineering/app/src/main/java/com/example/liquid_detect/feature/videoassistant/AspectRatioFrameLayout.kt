package com.example.liquid_detect.feature.videoassistant

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import kotlin.math.min
import kotlin.math.roundToInt

class AspectRatioFrameLayout @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {
    var aspectRatio: Float = 16f / 9f
        set(value) {
            val normalized = value.takeIf { it > 0f } ?: 16f / 9f
            if (field == normalized) return
            field = normalized
            requestLayout()
        }

    var maxContentHeightPx: Int = Int.MAX_VALUE
        set(value) {
            val normalized = if (value > 0) value else Int.MAX_VALUE
            if (field == normalized) return
            field = normalized
            requestLayout()
        }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        if (width <= 0) {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
            return
        }

        val contentWidth = (width - paddingLeft - paddingRight).coerceAtLeast(0)
        val desiredContentHeight = (contentWidth / aspectRatio).roundToInt().coerceAtLeast(0)
        val contentHeight = min(desiredContentHeight, maxContentHeightPx.coerceAtLeast(0))
        val measuredHeight = contentHeight + paddingTop + paddingBottom
        super.onMeasure(
            widthMeasureSpec,
            MeasureSpec.makeMeasureSpec(measuredHeight, MeasureSpec.EXACTLY),
        )
    }
}
