package com.example.liquid_detect.ui.workflow

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.navigation.fragment.findNavController
import com.example.liquid_detect.R
import com.example.liquid_detect.databinding.FragmentWorkflowHomeBinding
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantProcessingSessionState
import com.example.liquid_detect.feature.videoassistant.session.VideoAssistantSessionHolderViewModel
import kotlinx.coroutines.launch

class WorkflowHomeFragment : Fragment() {
    private var _binding: FragmentWorkflowHomeBinding? = null
    private val binding get() = _binding!!
    private val sessionHolder: VideoAssistantSessionHolderViewModel by activityViewModels()
    private lateinit var videoAssistantSummaryBinder: WorkflowHomeVideoAssistantSummaryBinder
    private val cameraPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            handleAction(WorkflowHomeActionResolver.resolveCameraPermissionResult(granted))
        }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        _binding = FragmentWorkflowHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        videoAssistantSummaryBinder =
            WorkflowHomeVideoAssistantSummaryBinder(
                summaryGroup = binding.groupVideoAssistantSessionSummary,
                statusView = binding.textVideoAssistantProcessingStatus,
                progressView = binding.progressVideoAssistantSession,
                detailView = binding.textVideoAssistantProcessingDetail,
            )
        binding.cardVideoAssistant.setOnClickListener {
            handleAction(
                WorkflowHomeActionResolver.resolveTap(
                    entryPoint = WorkflowHomeEntryPoint.VideoAssistantCard,
                    hasCameraPermission = hasCameraPermission(),
                ),
            )
        }
        binding.buttonOpenVideoAssistant.setOnClickListener {
            handleAction(
                WorkflowHomeActionResolver.resolveTap(
                    entryPoint = WorkflowHomeEntryPoint.VideoAssistantButton,
                    hasCameraPermission = hasCameraPermission(),
                ),
            )
        }
        binding.cardCameraCapture.setOnClickListener {
            handleAction(
                WorkflowHomeActionResolver.resolveTap(
                    entryPoint = WorkflowHomeEntryPoint.CameraCaptureCard,
                    hasCameraPermission = hasCameraPermission(),
                ),
            )
        }
        binding.buttonOpenCameraCapture.setOnClickListener {
            handleAction(
                WorkflowHomeActionResolver.resolveTap(
                    entryPoint = WorkflowHomeEntryPoint.CameraCaptureButton,
                    hasCameraPermission = hasCameraPermission(),
                ),
            )
        }

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                sessionHolder.session.state.collect(::renderVideoAssistantSessionSummary)
            }
        }
    }

    private fun renderVideoAssistantSessionSummary(state: VideoAssistantProcessingSessionState) {
        if (_binding == null) return
        videoAssistantSummaryBinder.bind(state)
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun handleAction(action: WorkflowHomeAction) {
        when (action) {
            WorkflowHomeAction.OpenVideoAssistant -> {
                findNavController().navigate(R.id.action_nav_workflow_home_to_nav_video_assistant)
            }

            WorkflowHomeAction.OpenCameraCapture -> navigateToCameraCapture()

            WorkflowHomeAction.RequestCameraPermission -> {
                cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
            }

            WorkflowHomeAction.ShowCameraPermissionDenied -> {
                if (isAdded) {
                    Toast.makeText(requireContext(), R.string.camera_permission_denied, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun navigateToCameraCapture() {
        findNavController().navigate(R.id.action_nav_workflow_home_to_nav_camera_capture)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
