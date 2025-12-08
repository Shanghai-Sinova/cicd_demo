package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class BrainstormRequest(
    @SerialName("first_idea") val firstIdea: String,
    @SerialName("num_ideas") val numIdeas: Int = 5,
    @SerialName("creative_style") val creativeStyle: List<String> = emptyList(),
    @SerialName("concept_type") val conceptType: String? = null,
    @SerialName("plot_type") val plotType: String? = null,
    @SerialName("project_id") val projectId: String? = null
)

@Serializable
data class BrainstormResponse(
    val success: Boolean? = null,
    val message: String? = null,
    val data: BrainstormPayload? = null
)

@Serializable
data class BrainstormPayload(
    @SerialName("brainstorm_ideas") val brainstormIdeas: List<String>? = null
)

@Serializable
data class StoryCoreAdvanceRequest(
    @SerialName("project_id") val projectId: String,
    @SerialName("story_core") val storyCore: String,
    @SerialName("leading_quantity") val leadingQuantity: Int = 1
)

@Serializable
data class ProtagonistResponse(
    val success: Boolean,
    val message: String? = null,
    val data: ProtagonistPayload? = null
)

@Serializable
data class ProtagonistPayload(
    @SerialName("leading_brief") val leadingBrief: String? = null
)

@Serializable
data class GenerateResponse(
    val success: Boolean,
    val message: String? = null,
    val content: String? = null,
    val data: GenerateData? = null
)

@Serializable
data class GenerateData(
    @SerialName("project_id") val projectId: String? = null,
    val sequence: String? = null
)

@Serializable
data class SequenceBeatResponse(
    val success: Boolean,
    val message: String? = null,
    val data: SequenceBeatData? = null
)

@Serializable
data class SequenceBeatData(
    @SerialName("sequence_id") val sequenceId: String,
    @SerialName("scene_beats") val sceneBeats: List<String>? = null
)

@Serializable
data class SequenceScriptResponse(
    val success: Boolean,
    val message: String? = null,
    val data: SequenceScriptData? = null
)

@Serializable
data class SequenceScriptData(
    @SerialName("generated_content") val generatedContent: String? = null
)
