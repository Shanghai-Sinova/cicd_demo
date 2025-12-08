package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.ProjectDto
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch

data class HomeStats(
    val total: Int = 0,
    val active: Int = 0,
    val completed: Int = 0,
    val words: Int = 0
)

class HomeViewModel(private val repository: NovelRepository) : ViewModel() {
    var stats by mutableStateOf(HomeStats())
        private set

    var projects by mutableStateOf<List<ProjectDto>>(emptyList())
        private set

    var isLoading by mutableStateOf(false)
        private set

    var error by mutableStateOf<String?>(null)
        private set

    fun load() {
        viewModelScope.launch {
            isLoading = true
            error = null
            val result = repository.fetchProjects(search = null, status = null)
            if (result.isSuccess) {
                val payload = result.getOrNull()
                val list = payload?.projects ?: emptyList()
                projects = list
                stats = HomeStats(
                    total = payload?.total ?: list.size,
                    active = list.count { it.status == "in_progress" || it.status == "active" },
                    completed = list.count { it.status == "completed" },
                    words = list.sumOf { it.metadata?.wordCount ?: 0 }
                )
            } else {
                error = result.exceptionOrNull()?.message
            }
            isLoading = false
        }
    }
}
