package com.example.liquid_detect.feature.camera.presentation

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.example.liquid_detect.R

internal class CameraCaptureProfileResolutionAdapter(
    private val onClick: (CameraCaptureProfileResolutionItemUi) -> Unit,
) : RecyclerView.Adapter<CameraCaptureProfileResolutionAdapter.ProfileViewHolder>() {
    private val items = mutableListOf<CameraCaptureProfileResolutionItemUi>()

    fun submitList(newItems: List<CameraCaptureProfileResolutionItemUi>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ProfileViewHolder {
        val view =
            LayoutInflater.from(parent.context)
                .inflate(R.layout.item_camera_capture_profile_option, parent, false)
        return ProfileViewHolder(view, onClick)
    }

    override fun onBindViewHolder(holder: ProfileViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    internal class ProfileViewHolder(
        itemView: View,
        private val onClick: (CameraCaptureProfileResolutionItemUi) -> Unit,
    ) : RecyclerView.ViewHolder(itemView) {
        private val title = itemView.findViewById<TextView>(R.id.textProfileOptionTitle)
        private val subtitle = itemView.findViewById<TextView>(R.id.textProfileOptionSubtitle)

        fun bind(item: CameraCaptureProfileResolutionItemUi) {
            title.text = item.title
            subtitle.text = item.subtitle
            subtitle.visibility = if (item.subtitle.isNullOrBlank()) View.GONE else View.VISIBLE
            itemView.alpha = if (item.enabled) 1f else 0.45f
            itemView.isEnabled = item.enabled
            itemView.setBackgroundResource(
                if (item.selected) {
                    R.drawable.bg_shell_playback_action
                } else {
                    android.R.color.transparent
                },
            )
            val titleColor =
                if (item.enabled) {
                    R.color.shell_text_primary
                } else {
                    R.color.shell_text_secondary
                }
            title.setTextColor(ContextCompat.getColor(itemView.context, titleColor))
            subtitle.setTextColor(ContextCompat.getColor(itemView.context, R.color.shell_text_secondary))
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
