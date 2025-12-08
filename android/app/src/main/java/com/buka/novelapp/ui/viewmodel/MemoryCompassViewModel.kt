package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.MediaAsset
import com.buka.novelapp.data.model.MemoryCompassNode
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch

data class MemoryCompassUiState(
    val projectId: String = "",
    val focus: String = "",
    val anchorInput: String = "",
    val anchors: List<String> = emptyList(),
    val nodes: List<MemoryCompassNode> = emptyList(),
    val isLoadingCompass: Boolean = false,
    val compassError: String? = null,
    val imagePrompt: String = "",
    val imageStyle: String = "",
    val imageAsset: MediaAsset? = null,
    val isLoadingImage: Boolean = false,
    val imageError: String? = null,
    val videoPrompt: String = "",
    val videoSeconds: Int = 10,
    val videoAsset: MediaAsset? = null,
    val isLoadingVideo: Boolean = false,
    val videoError: String? = null
)

class MemoryCompassViewModel(private val repository: NovelRepository) : ViewModel() {
    var uiState by mutableStateOf(MemoryCompassUiState())
        private set

    fun updateProjectId(value: String) { uiState = uiState.copy(projectId = value) }

    fun updateFocus(value: String) { uiState = uiState.copy(focus = value) }

    fun updateAnchorInput(value: String) { uiState = uiState.copy(anchorInput = value) }

    fun addAnchor() {
        if (uiState.anchorInput.isBlank()) return
        val updated = (uiState.anchors + uiState.anchorInput.trim()).distinct().take(8)
        uiState = uiState.copy(anchors = updated, anchorInput = "")
    }

    fun removeAnchor(anchor: String) {
        uiState = uiState.copy(anchors = uiState.anchors.filterNot { it == anchor })
    }

    fun generateCompass() {
        if (uiState.focus.isBlank()) {
            uiState = uiState.copy(compassError = "请先输入记忆焦点")
            return
        }
        viewModelScope.launch {
            uiState = uiState.copy(isLoadingCompass = true, compassError = null)
            val result = repository.generateMemoryCompass(
                projectId = uiState.projectId.ifBlank { "" },
                focus = uiState.focus,
                anchors = uiState.anchors
            )
            uiState = if (result.isSuccess) {
                uiState.copy(nodes = result.getOrNull()?.nodes ?: emptyList(), isLoadingCompass = false)
            } else {
                uiState.copy(isLoadingCompass = false, compassError = result.exceptionOrNull()?.message)
            }
        }
    }

    fun updateImagePrompt(value: String) { uiState = uiState.copy(imagePrompt = value) }

    fun updateImageStyle(value: String) { uiState = uiState.copy(imageStyle = value) }

    fun generateImage() {
        if (uiState.imagePrompt.isBlank()) {
            uiState = uiState.copy(imageError = "请填写图片提示")
            return
        }
        viewModelScope.launch {
            uiState = uiState.copy(isLoadingImage = true, imageError = null, imageAsset = null)
            val result = repository.generateImage(uiState.imagePrompt, uiState.imageStyle.ifBlank { null })
            uiState = if (result.isSuccess) {
                uiState.copy(isLoadingImage = false, imageAsset = result.getOrNull()?.data)
            } else {
                uiState.copy(isLoadingImage = false, imageError = result.exceptionOrNull()?.message)
            }
        }
    }

    fun updateVideoPrompt(value: String) { uiState = uiState.copy(videoPrompt = value) }

    fun updateVideoSeconds(value: String) {
        val parsed = value.toIntOrNull()?.coerceIn(3, 60) ?: uiState.videoSeconds
        uiState = uiState.copy(videoSeconds = parsed)
    }

    fun generateVideo() {
        if (uiState.videoPrompt.isBlank()) {
            uiState = uiState.copy(videoError = "请填写视频提示")
            return
        }
        viewModelScope.launch {
            uiState = uiState.copy(isLoadingVideo = true, videoError = null, videoAsset = null)
            val result = repository.generateVideo(uiState.videoPrompt, uiState.videoSeconds)
            uiState = if (result.isSuccess) {
                uiState.copy(isLoadingVideo = false, videoAsset = result.getOrNull()?.data)
            } else {
                uiState.copy(isLoadingVideo = false, videoError = result.exceptionOrNull()?.message)
            }
        }
    }
}
