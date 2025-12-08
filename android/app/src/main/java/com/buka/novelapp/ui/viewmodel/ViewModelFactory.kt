package com.buka.novelapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.buka.novelapp.data.repository.NovelRepository

class ViewModelFactory(private val repository: NovelRepository) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(AuthViewModel::class.java) -> AuthViewModel(repository) as T
            modelClass.isAssignableFrom(HomeViewModel::class.java) -> HomeViewModel(repository) as T
            modelClass.isAssignableFrom(ProjectsViewModel::class.java) -> ProjectsViewModel(repository) as T
            modelClass.isAssignableFrom(CreationViewModel::class.java) -> CreationViewModel(repository) as T
            modelClass.isAssignableFrom(MultiNarrativeViewModel::class.java) -> MultiNarrativeViewModel(repository) as T
            modelClass.isAssignableFrom(MemoryCompassViewModel::class.java) -> MemoryCompassViewModel(repository) as T
            modelClass.isAssignableFrom(UserCenterViewModel::class.java) -> UserCenterViewModel(repository) as T
            else -> throw IllegalArgumentException("Unknown ViewModel: ${modelClass.name}")
        }
    }
}
