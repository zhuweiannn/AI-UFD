package com.example.liquid_detect.feature.camera

import android.os.Bundle
import android.view.LayoutInflater
import android.view.SurfaceHolder
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.example.liquid_detect.databinding.FragmentCaptureBinding

class CameraCaptureFragment : Fragment(), SurfaceHolder.Callback {
    private var _binding: FragmentCaptureBinding? = null
    private val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        _binding = FragmentCaptureBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        // ... camera permission, model loading, recording, and native preview workflow omitted.
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        // ... native camera preview binding omitted.
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // ... native camera surface update omitted.
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        // ... native camera surface teardown omitted.
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
