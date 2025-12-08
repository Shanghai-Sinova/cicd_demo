package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.BrainstormRequest
import com.buka.novelapp.data.model.SequenceBeatResponse
import com.buka.novelapp.data.model.SequenceScriptResponse
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONException

enum class CreationStepKind(val title: String, val description: String) {
    INSPIRATION("输入灵感", "生成灵感与故事核心"),
    STORY_CORE("故事核心", "深化故事设定"),
    PROTAGONIST("主角人物", "生成主角设定"),
    RELATIONSHIPS("配角关系", "生成配角与关系"),
    PLOT("情节序列", "生成序列与节拍"),
    WRITING("正文生成", "根据节拍生成正文")
}

enum class StepStatus { IDLE, RUNNING, COMPLETED, FAILED }

data class CreationStepState(
    val kind: CreationStepKind,
    val status: StepStatus = StepStatus.IDLE,
    val preview: String = "",
    val updatedAtMillis: Long? = null
)

data class CreationUiState(
    val projectId: String = "",
    val projectName: String = "",
    val firstIdea: String = "",
    val storyCore: String = "",
    val protagonist: String = "",
    val supporting: List<String> = emptyList(),
    val plotSequence: String = "",
    val sceneBeats: List<String> = emptyList(),
    val script: String = "",
    val brainstormIdeas: List<String> = emptyList(),
    val steps: List<CreationStepState> = CreationStepKind.values().map { CreationStepState(it) },
    val error: String? = null,
    val isLoading: Boolean = false
)

class CreationViewModel(private val repository: NovelRepository) : ViewModel() {
    var uiState by mutableStateOf(CreationUiState())
        private set

    fun updateProjectId(value: String) {
        uiState = uiState.copy(projectId = value)
    }

    fun updateProjectName(value: String) {
        uiState = uiState.copy(projectName = value)
    }

    fun updateFirstIdea(value: String) {
        uiState = uiState.copy(firstIdea = value)
    }

    fun attachProject() {
        val id = uiState.projectId
        if (id.isBlank()) return
        viewModelScope.launch {
            uiState = uiState.copy(isLoading = true)
            val result = repository.fetchProject(id)
            uiState = if (result.isSuccess) {
                val project = result.getOrNull()
                uiState.copy(
                    projectName = project?.projectName ?: uiState.projectName,
                    firstIdea = project?.firstIdea ?: project?.firstIdeaLegacy ?: uiState.firstIdea,
                    storyCore = project?.storyCore ?: uiState.storyCore,
                    protagonist = project?.leadingBrief ?: uiState.protagonist,
                    error = null,
                    isLoading = false
                )
            } else {
                uiState.copy(error = result.exceptionOrNull()?.message, isLoading = false)
            }
        }
    }

    fun ensureProject() {
        if (uiState.projectId.isNotBlank()) return
        viewModelScope.launch {
            uiState = uiState.copy(isLoading = true)
            val result = repository.createProject(
                name = if (uiState.projectName.isBlank()) "移动端项目" else uiState.projectName,
                idea = uiState.firstIdea.takeIf { it.isNotBlank() }
            )
            uiState = if (result.isSuccess) {
                val project = result.getOrNull()
                uiState.copy(
                    projectId = project?.projectId ?: uiState.projectId,
                    projectName = project?.projectName ?: uiState.projectName,
                    error = null,
                    isLoading = false
                )
            } else {
                uiState.copy(error = result.exceptionOrNull()?.message, isLoading = false)
            }
        }
    }

    fun runStep(kind: CreationStepKind) {
        viewModelScope.launch {
            if (uiState.projectId.isBlank()) ensureProject()
            updateStep(kind, StepStatus.RUNNING, null)
            when (kind) {
                CreationStepKind.INSPIRATION -> runBrainstorm()
                CreationStepKind.STORY_CORE -> runStoryCore()
                CreationStepKind.PROTAGONIST -> runProtagonist()
                CreationStepKind.RELATIONSHIPS -> runSupporting()
                CreationStepKind.PLOT -> runPlot()
                CreationStepKind.WRITING -> runWriting()
            }
        }
    }

    private suspend fun runBrainstorm() {
        val idea = if (uiState.firstIdea.isBlank()) "请生成一部都市奇幻爱情故事" else uiState.firstIdea
        val response = repository.generateBrainstorm(
            BrainstormRequest(firstIdea = idea, projectId = uiState.projectId.ifBlank { null })
        )
        val ideas = response.data?.brainstormIdeas ?: emptyList()
        uiState = uiState.copy(brainstormIdeas = ideas, storyCore = ideas.firstOrNull() ?: uiState.storyCore)
        if (!uiState.storyCore.isBlank()) {
            repository.advanceStoryCore(uiState.projectId, uiState.storyCore)
        }
        updateStep(CreationStepKind.INSPIRATION, StepStatus.COMPLETED, uiState.storyCore)
    }

    private suspend fun runStoryCore() {
        if (uiState.storyCore.isBlank()) return
        repository.advanceStoryCore(uiState.projectId, uiState.storyCore)
        updateStep(CreationStepKind.STORY_CORE, StepStatus.COMPLETED, uiState.storyCore)
    }

    private suspend fun runProtagonist() {
        val response = repository.generateProtagonist(uiState.projectId)
        val content = response.data?.leadingBrief ?: ""
        if (content.isNotBlank()) {
            uiState = uiState.copy(protagonist = content)
        }
        updateStep(CreationStepKind.PROTAGONIST, StepStatus.COMPLETED, uiState.protagonist)
    }

    private suspend fun runSupporting() {
        val response = repository.generateSupporting(uiState.projectId)
        val characters = parseCharacters(response.content)
        uiState = uiState.copy(supporting = characters)
        updateStep(CreationStepKind.RELATIONSHIPS, StepStatus.COMPLETED, characters.firstOrNull() ?: "")
    }

    private suspend fun runPlot() {
        repository.generatePlot(uiState.projectId)
        val beatResponse: SequenceBeatResponse = repository.generateBeats(uiState.projectId, "seq_main")
        val beats = beatResponse.data?.sceneBeats ?: emptyList()
        uiState = uiState.copy(sceneBeats = beats)
        updateStep(CreationStepKind.PLOT, StepStatus.COMPLETED, beats.firstOrNull() ?: "")
    }

    private suspend fun runWriting() {
        val beats = if (uiState.sceneBeats.isEmpty()) listOf("Scene 1: 引入") else uiState.sceneBeats
        val response: SequenceScriptResponse = repository.generateScripts(uiState.projectId, beats)
        val script = response.data?.generatedContent ?: ""
        uiState = uiState.copy(script = script)
        updateStep(CreationStepKind.WRITING, StepStatus.COMPLETED, script.take(120))
    }

    private fun updateStep(kind: CreationStepKind, status: StepStatus, preview: String?) {
        uiState = uiState.copy(
            steps = uiState.steps.map {
                if (it.kind == kind) {
                    it.copy(status = status, preview = preview ?: it.preview, updatedAtMillis = System.currentTimeMillis())
                } else it
            },
            error = if (status == StepStatus.FAILED) preview else null
        )
    }

    private fun parseCharacters(content: String?): List<String> {
        if (content.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(content)
            (0 until array.length()).mapNotNull { index ->
                val obj = array.optJSONObject(index)
                obj?.let {
                    val name = it.optString("name")
                    val desc = it.optString("description")
                    val relation = it.optString("relationship")
                    "$name - $desc $relation"
                }
            }
        } catch (err: JSONException) {
            content.lines()
        }
    }
}
