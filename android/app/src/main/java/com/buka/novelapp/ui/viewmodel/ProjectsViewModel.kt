package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.ProjectDto
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch

class ProjectsViewModel(private val repository: NovelRepository) : ViewModel() {
    var projects by mutableStateOf<List<ProjectDto>>(emptyList())
        private set

    var isLoading by mutableStateOf(false)
        private set

    var error by mutableStateOf<String?>(null)
        private set

    var search by mutableStateOf("")
    var statusFilter by mutableStateOf<String?>(null)

    var newProjectName by mutableStateOf("")
    var newProjectIdea by mutableStateOf("")
    var isCreating by mutableStateOf(false)

    fun load() {
        viewModelScope.launch { fetchProjects() }
    }

    fun updateSearch(value: String) {
        search = value
    }

    fun applyStatusFilter(value: String?) {
        statusFilter = value
        load()
    }

    fun fetchProjects() {
        viewModelScope.launch {
            isLoading = true
            error = null
            val result = repository.fetchProjects(search.takeIf { it.isNotBlank() }, statusFilter)
            if (result.isSuccess) {
                projects = result.getOrNull()?.projects ?: emptyList()
            } else {
                error = result.exceptionOrNull()?.message
            }
            isLoading = false
        }
    }

    fun createProject() {
        if (newProjectName.isBlank()) return
        viewModelScope.launch {
            isCreating = true
            val result = repository.createProject(newProjectName, newProjectIdea)
            if (result.isSuccess) {
                projects = listOf(result.getOrNull()!!) + projects
                newProjectName = ""
                newProjectIdea = ""
            } else {
                error = result.exceptionOrNull()?.message
            }
            isCreating = false
        }
    }

    fun toggleFavorite(project: ProjectDto) {
        viewModelScope.launch {
            val updated = repository.updateProject(project.projectId, mapOf(
                "is_favorite" to !(project.isFavorite ?: false)
            ))
            if (updated.isSuccess) {
                val target = updated.getOrNull()
                projects = projects.map { if (it.projectId == target?.projectId) target else it }
            } else {
                error = updated.exceptionOrNull()?.message
            }
        }
    }

    fun delete(project: ProjectDto) {
        viewModelScope.launch {
            repository.deleteProject(project.projectId)
            projects = projects.filterNot { it.projectId == project.projectId }
        }
    }
}
