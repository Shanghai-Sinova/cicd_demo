package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class MemoryCompassRequest(
    @SerialName("project_id") val projectId: String,
    val focus: String,
    val anchors: List<String> = emptyList()
)

@Serializable
data class MemoryCompassNode(
    val title: String,
    val summary: String,
    val relation: String? = null
)

@Serializable
data class MemoryCompassPayload(
    val nodes: List<MemoryCompassNode> = emptyList()
)

@Serializable
data class MemoryCompassResponse(
    val success: Boolean? = null,
    val message: String? = null,
    val data: MemoryCompassPayload? = null
)

@Serializable
data class MediaGenerateRequest(
    val prompt: String,
    val style: String? = null,
    @SerialName("seconds") val seconds: Int? = null
)

@Serializable
data class MediaAsset(
    val url: String? = null,
    @SerialName("preview") val preview: String? = null,
    @SerialName("request_id") val requestId: String? = null
)

@Serializable
data class MediaGenerateResponse(
    val success: Boolean? = null,
    val message: String? = null,
    val data: MediaAsset? = null
)
