package com.example.liquid_detect.inference

import android.content.res.AssetManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

enum class ModelTask(
    val wireValue: String,
    val apiGroup: String,
) {
    DETECT("detect", "yolo"),
    SEGMENT("segment", "yolo_seg");

    companion object {
        fun fromWireValue(value: String?): ModelTask {
            return values().firstOrNull { it.wireValue == value } ?: DETECT
        }
    }
}

data class AppModelSpec(
    val id: String,
    val displayName: String,
    val assetBasename: String,
    val targetSize: Int,
    val computeModel: String,
    val isDefault: Boolean,
    val task: ModelTask,
)

private data class RawAppModelSpec(
    val id: String,
    val display_name: String,
    val asset_basename: String,
    val target_size: Int,
    val compute_model: String,
    val default: Boolean = false,
    val task: String? = null,
)

object ModelCatalog {
    private const val CATALOG_FILE = "models.json"
    private val gson = Gson()

    fun load(assetManager: AssetManager, fileName: String = CATALOG_FILE): List<AppModelSpec> {
        val json = assetManager.open(fileName).bufferedReader().use { it.readText() }
        return parseJson(json)
    }

    fun parseJson(json: String): List<AppModelSpec> {
        val type = object : TypeToken<List<RawAppModelSpec>>() {}.type
        val raw: List<RawAppModelSpec> = gson.fromJson(json, type) ?: emptyList()
        return raw.map { item ->
            AppModelSpec(
                id = item.id,
                displayName = item.display_name,
                assetBasename = item.asset_basename,
                targetSize = item.target_size,
                computeModel = item.compute_model,
                isDefault = item.default,
                task = ModelTask.fromWireValue(item.task),
            )
        }
    }

    fun resolveInitialIndex(models: List<AppModelSpec>, savedModelId: String?): Int {
        if (models.isEmpty()) return -1
        val savedIndex =
            savedModelId?.let { id ->
                models.indexOfFirst { it.id == id }
            } ?: -1
        if (savedIndex >= 0) return savedIndex

        val defaultIndex = models.indexOfFirst { it.isDefault }
        return if (defaultIndex >= 0) defaultIndex else 0
    }
}
