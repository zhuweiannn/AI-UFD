package com.example.liquid_detect.feature.videoassistant

import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.example.liquid_detect.databinding.FragmentVideoAssistantBinding
import com.example.liquid_detect.inference.AppModelSpec

class VideoAssistantFragment : Fragment() {
    private data class StartProcessingTarget(
        val uri: Uri,
        val metadata: VideoFileMetadata,
        val spec: AppModelSpec,
        val sourceFingerprint: String,
    )

    private enum class StageContainerMode {
        Choose,
        Detail,
        Hidden,
    }

    private var _binding: FragmentVideoAssistantBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        _binding = FragmentVideoAssistantBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        // ... video selection, local replay, analysis upload, and workflow implementation omitted.
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
