package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ProjectDto(
    @SerialName("project_id") val projectId: String,
    @SerialName("project_name") val projectName: String,
    val status: String,
    @SerialName("is_favorite") val isFavorite: Boolean? = null,
    val tags: List<String>? = null,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("story_core") val storyCore: String? = null,
    @SerialName("leading_brief") val leadingBrief: String? = null,
    @SerialName("firstIdea") val firstIdea: String? = null,
    @SerialName("first_idea") val firstIdeaLegacy: String? = null,
    @SerialName("brainstorm_ideas") val brainstormIdeas: List<String>? = null,
    val metadata: ProjectMetadataDto? = null
)

@Serializable
data class ProjectMetadataDto(
    @SerialName("word_count") val wordCount: Int? = null,
    @SerialName("chapter_count") val chapterCount: Int? = null,
    @SerialName("character_count") val characterCount: Int? = null
)

@Serializable
data class ProjectsPayload(
    val projects: List<ProjectDto> = emptyList(),
    val pagination: Pagination? = null,
    val total: Int? = null,
    val page: Int? = null,
    val limit: Int? = null
)
