package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class MultiNarrativeBranchInput(
    @SerialName("branch_title") val branchTitle: String,
    val goal: String? = null,
    val tone: String? = null
)

@Serializable
data class MultiNarrativeRequest(
    @SerialName("project_id") val projectId: String,
    val theme: String,
    val branches: List<MultiNarrativeBranchInput>,
    @SerialName("max_tokens") val maxTokens: Int? = null
)

@Serializable
data class StoryBranchDto(
    @SerialName("branch_title") val branchTitle: String,
    val synopsis: String,
    @SerialName("beat_outline") val beatOutline: List<String>? = null,
    val hook: String? = null
)

@Serializable
data class MultiNarrativePayload(
    val branches: List<StoryBranchDto> = emptyList(),
    @SerialName("token_usage") val tokenUsage: TokenUsageDto? = null
)

@Serializable
data class MultiNarrativeResponse(
    val success: Boolean? = null,
    val message: String? = null,
    val data: MultiNarrativePayload? = null
)
