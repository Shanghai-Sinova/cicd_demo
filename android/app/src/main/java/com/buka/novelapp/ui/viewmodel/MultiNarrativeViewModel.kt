package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.MultiNarrativeBranchInput
import com.buka.novelapp.data.model.MultiNarrativePayload
import com.buka.novelapp.data.model.StoryBranchDto
import com.buka.novelapp.data.model.TokenEstimator
import com.buka.novelapp.data.model.TokenUsageDto
import com.buka.novelapp.data.model.TokenUsageEstimate
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch

data class BranchFormState(
    val title: String = "",
    val goal: String = "",
    val tone: String = ""
)

data class MultiNarrativeUiState(
    val projectId: String = "",
    val theme: String = "",
    val targetTokens: Int = 512,
    val branches: List<BranchFormState> = listOf(
        BranchFormState(title = "主线A"),
        BranchFormState(title = "支线B")
    ),
    val estimated: TokenUsageEstimate = TokenEstimator.estimateForBranches("", emptyList(), 512),
    val remoteUsage: TokenUsageDto? = null,
    val results: List<StoryBranchDto> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null
)

class MultiNarrativeViewModel(private val repository: NovelRepository) : ViewModel() {
    var uiState by mutableStateOf(MultiNarrativeUiState())
        private set

    fun updateProjectId(value: String) {
        uiState = uiState.copy(projectId = value)
    }

    fun updateTheme(value: String) {
        updateState { copy(theme = value) }
    }

    fun updateTargetTokens(value: String) {
        val parsed = value.toIntOrNull()?.coerceAtLeast(1) ?: uiState.targetTokens
        updateState { copy(targetTokens = parsed) }
    }

    fun updateBranchTitle(index: Int, value: String) {
        updateBranch(index) { copy(title = value) }
    }

    fun updateBranchGoal(index: Int, value: String) {
        updateBranch(index) { copy(goal = value) }
    }

    fun updateBranchTone(index: Int, value: String) {
        updateBranch(index) { copy(tone = value) }
    }

    fun addBranch() {
        if (uiState.branches.size >= 6) return
        updateState { copy(branches = branches + BranchFormState(title = "分支${branches.size + 1}")) }
    }

    fun removeBranch(index: Int) {
        if (uiState.branches.size <= 1 || index !in uiState.branches.indices) return
        updateState { copy(branches = branches.filterIndexed { i, _ -> i != index }) }
    }

    fun generate() {
        val snapshot = uiState
        val validBranches = snapshot.branches.filter { branchInputString(it).isNotBlank() }
        if (snapshot.theme.isBlank() || validBranches.isEmpty()) {
            uiState = snapshot.copy(error = "请先填写主题和至少一条分支")
            return
        }
        viewModelScope.launch {
            uiState = snapshot.copy(
                isLoading = true,
                error = null,
                results = emptyList(),
                remoteUsage = null,
                estimated = TokenEstimator.estimateForBranches(
                    snapshot.theme,
                    validBranches.map(::branchInputString),
                    snapshot.targetTokens
                )
            )
            val requestBranches = validBranches.map {
                MultiNarrativeBranchInput(
                    branchTitle = it.title.ifBlank { "分支" },
                    goal = it.goal.ifBlank { null },
                    tone = it.tone.ifBlank { null }
                )
            }
            val response = repository.generateMultiNarrative(
                projectId = snapshot.projectId,
                theme = snapshot.theme,
                branches = requestBranches,
                maxTokens = snapshot.targetTokens
            )
            uiState = if (response.isSuccess) {
                val payload: MultiNarrativePayload = response.getOrNull() ?: MultiNarrativePayload()
                val next = uiState.copy(
                    isLoading = false,
                    results = payload.branches,
                    remoteUsage = payload.tokenUsage,
                    error = null
                )
                next.copy(
                    estimated = TokenEstimator.estimateForBranches(
                        next.theme,
                        next.branches.map(::branchInputString),
                        next.targetTokens
                    )
                )
            } else {
                uiState.copy(isLoading = false, error = response.exceptionOrNull()?.message ?: "生成失败")
            }
        }
    }

    private fun updateBranch(index: Int, transform: BranchFormState.() -> BranchFormState) {
        if (index !in uiState.branches.indices) return
        val updated = uiState.branches.mapIndexed { i, branch -> if (i == index) branch.transform() else branch }
        updateState { copy(branches = updated) }
    }

    private fun updateState(modifier: MultiNarrativeUiState.() -> MultiNarrativeUiState) {
        val next = uiState.modifier()
        uiState = next.copy(
            estimated = TokenEstimator.estimateForBranches(
                next.theme,
                next.branches.map(::branchInputString),
                next.targetTokens
            )
        )
    }
}

private fun branchInputString(branch: BranchFormState): String {
    return listOf(branch.title, branch.goal, branch.tone).joinToString(" ").trim()
}
