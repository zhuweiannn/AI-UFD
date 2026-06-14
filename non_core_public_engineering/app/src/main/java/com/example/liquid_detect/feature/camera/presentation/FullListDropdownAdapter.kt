package com.example.liquid_detect.feature.camera.presentation

import android.content.Context
import android.widget.ArrayAdapter
import android.widget.Filter

internal class FullListDropdownAdapter(
    context: Context,
    resource: Int,
    textViewResourceId: Int,
) : ArrayAdapter<String>(context, resource, textViewResourceId, mutableListOf()) {
    private val allItems = mutableListOf<String>()

    private val noFilter =
        object : Filter() {
            override fun performFiltering(constraint: CharSequence?): FilterResults {
                return FilterResults().apply {
                    values = allItems.toList()
                    count = allItems.size
                }
            }

            override fun publishResults(constraint: CharSequence?, results: FilterResults?) {
                val items = (results?.values as? List<*>)?.filterIsInstance<String>().orEmpty()
                super@FullListDropdownAdapter.clear()
                super@FullListDropdownAdapter.addAll(items)
                notifyDataSetChanged()
            }

            override fun convertResultToString(resultValue: Any?): CharSequence {
                return resultValue?.toString().orEmpty()
            }
        }

    override fun getFilter(): Filter = noFilter

    fun replaceAll(items: List<String>) {
        allItems.clear()
        allItems.addAll(items)
        super.clear()
        super.addAll(items)
        notifyDataSetChanged()
    }
}
