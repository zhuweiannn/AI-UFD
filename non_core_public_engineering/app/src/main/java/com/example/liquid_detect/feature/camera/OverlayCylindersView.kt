package com.example.liquid_detect.feature.camera

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.util.TypedValue
import android.view.View
import androidx.core.graphics.toColorInt
import kotlin.math.max
import kotlin.math.min

class OverlayCylindersView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : View(context, attrs) {

    enum class AxisMode { COMPACT, LABELED }

    private var cylinderCount = 4
    private var maxMl = 100f
    private var levels = FloatArray(cylinderCount) { 0f }

    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = dp(2f)
        color = "#304455".toColorInt()
    }
    private val liquidPaints = arrayOf(
        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = "#8842A5F5".toColorInt() },
        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = "#88EF5350".toColorInt() },
        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = "#884CAF50".toColorInt() },
        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = "#88FFB300".toColorInt() },
    )

    private val tickPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#80304455".toColorInt()
        strokeWidth = dp(1f)
    }
    private val gridMinorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#20304455".toColorInt()
        strokeWidth = dp(1f)
    }
    private val gridMajorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#40304455".toColorInt()
        strokeWidth = dp(1.2f)
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#80304455".toColorInt()
        textSize = sp(10f)
    }
    private val guidePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#663F51B5".toColorInt()
        strokeWidth = dp(1.5f)
        pathEffect = DashPathEffect(floatArrayOf(dp(6f), dp(4f)), 0f)
    }

    // ====== 新增：轴模式/紧凑参数 ======
    private var axisMode: AxisMode = AxisMode.COMPACT
    fun setAxisMode(mode: AxisMode) { axisMode = mode; invalidate() }

    private var compactAxisWidthDp = 12f        // 紧凑轴宽度（仅刻度，不含文字）
    private var compactMinorLenDp = 4f
    private var compactMajorLenDp = 6f

    // 可选：量筒标题是否显示当前 ml
    private var showValueOnLabel = false
    fun setShowValueOnLabel(show: Boolean) { showValueOnLabel = show; invalidate() }

    // 可选：统一指示线
    private var guideLineMl: Float? = null
    fun setGuideLine(ml: Float?) { guideLineMl = ml?.coerceIn(0f, maxMl); invalidate() }

    // 刻度步长
    private var minorStep = 10
    private var majorStep = 50
    fun setSteps(minor: Int = 10, major: Int = 50) {
        minorStep = max(1, minor)
        majorStep = max(minorStep, major)
        invalidate()
    }

    private val outerRect = RectF()
    private val cylAreaRect = RectF()
    private val tmpRect = RectF()

    /** 外部设置：量筒数 + 刻度上限（ml） */
    fun configureCylinders(count: Int, maxMlLimit: Int = 100) {
        cylinderCount = max(1, count)
        this.maxMl = max(1, maxMlLimit).toFloat()
        val old = levels
        val newLevels = FloatArray(cylinderCount) { i ->
            val v = if (i < old.size) old[i] else 0f
            v.coerceIn(0f, this.maxMl)
        }
        levels = newLevels
        invalidate()
    }

    /** 设置某个量筒液位（ml） */
    fun setLevel(index: Int, ml: Float) {
        if (index !in 0 until cylinderCount) return
        levels[index] = ml.coerceIn(0f, maxMl)
        invalidate()
    }

    /** 批量设置液位 */
    fun setLevels(allMl: List<Float>) {
        for (i in 0 until min(cylinderCount, allMl.size)) {
            levels[i] = allMl[i].coerceIn(0f, maxMl)
        }
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val pad = dp(8f)
        outerRect.set(pad, pad, width - pad, height - pad)
        if (outerRect.width() <= 0 || outerRect.height() <= 0) return

        // 根据模式决定右侧轴宽度
        val axisWidth = if (axisMode == AxisMode.LABELED) {
            val maxLabel = "${maxMl.toInt()}ml"
            val labelW = textPaint.measureText(maxLabel)
            max(dp(28f), labelW + dp(12f)) // 有文字时适当保留
        } else {
            dp(compactAxisWidthDp)         // 紧凑：固定极窄宽度
        }

        // 底部文本轴高度
        val fm = textPaint.fontMetrics
        val bottomLabelH = fm.descent - fm.ascent

        // 量筒绘制区域（不含右侧轴）
        cylAreaRect.set(outerRect.left, outerRect.top, outerRect.right - axisWidth, outerRect.bottom - bottomLabelH)
        if (cylAreaRect.width() <= 0) return

        // 统一轴 + 网格
        drawUnifiedAxisAndGrid(canvas, cylAreaRect, outerRect.right - axisWidth)

        // 画量筒
        val gap = dp(8f)
        val cylW = (cylAreaRect.width() - gap * (cylinderCount + 1)) / cylinderCount
        val cylH = cylAreaRect.height()
        for (i in 0 until cylinderCount) {
            val left = cylAreaRect.left + gap + i * (cylW + gap)
            val top = cylAreaRect.top
            val right = left + cylW
            val bottom = cylAreaRect.bottom

            tmpRect.set(left, top, right, bottom)
            canvas.drawRoundRect(tmpRect, dp(1f), dp(1f), strokePaint)

            val percent = (levels[i] / maxMl).coerceIn(0f, 1f)
            val liquidTop = bottom - cylH * percent
            val inset = dp(2f)
            val paint = liquidPaints[i % liquidPaints.size]
            canvas.drawRoundRect(
                tmpRect.left + inset,
                liquidTop,
                tmpRect.right - inset,
                tmpRect.bottom - inset,
                dp(2f), dp(2f), paint
            )

            val label = if (showValueOnLabel) "C${i + 1}: ${levels[i].toInt()}ml" else "C${i + 1}"
            canvas.drawText(
                label,
                tmpRect.centerX() - textPaint.measureText(label) / 2f,
                tmpRect.bottom + bottomLabelH,
                textPaint
            )
        }

        // 可选：统一指示线
        guideLineMl?.let { ml ->
            val y = cylAreaRect.bottom - cylAreaRect.height() * (ml / maxMl)
            canvas.drawLine(cylAreaRect.left, y, cylAreaRect.right, y, guidePaint)
        }
    }

    /** 右侧统一轴 + 贯穿网格；紧凑模式不绘制任何文字，只保留短刻度线与网格 */
    private fun drawUnifiedAxisAndGrid(canvas: Canvas, area: RectF, axisLeft: Float) {
        val isCompact = axisMode == AxisMode.COMPACT
        val x0 = axisLeft + dp(2f)
        val lenMinor = if (isCompact) dp(compactMinorLenDp) else dp(5f)
        val lenMajor = if (isCompact) dp(compactMajorLenDp) else dp(9f)

        val total = maxMl.toInt().coerceAtLeast(1)
        for (ml in 0..total step minorStep) {
            val p = ml / maxMl
            val y = area.bottom - area.height() * p
            val isMajor = (ml % majorStep == 0)

            // 网格线（贯穿量筒区域）——这不占轴空间，可保留，颜色很淡
            canvas.drawLine(
                area.left, y, area.right, y,
                if (isMajor) gridMajorPaint else gridMinorPaint
            )

            // 右侧短刻度
            val x1 = x0 + if (isMajor) lenMajor else lenMinor
            canvas.drawLine(x0, y, x1, y, tickPaint)

            // 仅在带文字模式下绘制“100ml/50ml…”
            if (!isCompact && isMajor) {
                val txt = "${ml}ml"
                canvas.drawText(txt, x1 + dp(2f), y + sp(3.5f), textPaint)
            }
        }
    }

    // utils
    private fun dp(v: Float) = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, v, resources.displayMetrics
    )
    private fun sp(v: Float) = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_SP, v, resources.displayMetrics
    )
}
