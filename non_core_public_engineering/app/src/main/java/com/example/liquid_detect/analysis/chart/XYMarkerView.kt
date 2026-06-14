package com.example.liquid_detect.analysis.chart


import android.content.Context
import android.widget.TextView
import com.github.mikephil.charting.components.MarkerView
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.utils.MPPointF
import com.github.mikephil.charting.charts.LineChart
import com.example.liquid_detect.R
import com.github.mikephil.charting.data.DataSet
import java.text.DecimalFormat
import kotlin.math.abs

class XYMarkerView(
    context: Context,
    private val chart: LineChart
) : MarkerView(context, R.layout.marker_view) {

    private val tv = findViewById<TextView>(R.id.tvContent)
    private val dfX = DecimalFormat("0.0")   // 秒
    private val dfY = DecimalFormat("0.00")  // 值

    // 选点时刷新内容
    override fun refreshContent(e: Entry?, highlight: Highlight?) {
        if (e == null) return

        // 高亮的 X（你这边是“相对秒”）
        val x = e.x
        val data = chart.data ?: return

        // 优先：从 Entry.data 直接拿（0-based）
        var idx0 = (e.data as? Int)

        // 兜底：从高亮数据集里用 x 找最近点再反查索引
        if (idx0 == null) {
            val tol = 1e-3f
            val setIdx = highlight?.dataSetIndex ?: 0
            val ds = data.getDataSetByIndex(setIdx)
            val match = ds?.getEntryForXValue(x, Float.NaN, DataSet.Rounding.CLOSEST)
            idx0 = match?.takeIf { kotlin.math.abs(it.x - x) <= tol }?.let { ds.getEntryIndex(it) }
        }

        // 显示为 1-based：第 N 个点
        val idxDisp = idx0?.plus(1) ?: "?"
        val sb = StringBuilder("t=${dfX.format(x)}s  (#$idxDisp)")

//        val sb = StringBuilder("t=${dfX.format(x)}s")

        // 遍历所有数据集，拿到同一 x 的点（允许细微误差）
//        val data = chart.data ?: return
        val tol = 1e-3f
        for (i in 0 until data.dataSetCount) {
            val ds = data.getDataSetByIndex(i)
            val label = ds.label ?: "S${i + 1}"

            // 精确匹配同 x 的点。如果你是稀疏点或浮点误差，考虑用 Rounding.CLOSEST 再判断差距
            val match = ds.getEntryForXValue(x, Float.NaN, DataSet.Rounding.CLOSEST)
            val y = match?.takeIf { abs(it.x - x) <= tol }?.y

            if (y != null) {
                sb.append("\n").append(label).append(": ").append(dfY.format(y))
            }
        }

        tv.text = sb.toString()
        super.refreshContent(e, highlight)
    }

    // 让 marker 在高亮点上方居中显示
    override fun getOffset(): MPPointF {
        // 注意：调用时宽高已测量过（draw 前）
        return MPPointF(-(width / 2f), -height.toFloat() - 8f)
    }
}
