package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.UserDto
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class AuthUiState(
    val username: String = "user001",
    val password: String = "abcd123456",
    val email: String = "user001@example.com",
    val nickname: String = "新用户",
    val isRegisterMode: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val user: UserDto? = null
)

class AuthViewModel(private val repository: NovelRepository) : ViewModel() {
    private val tokenFlow = repository.tokenFlow
    val hasToken: StateFlow<Boolean> = tokenFlow
        .map { !it.isNullOrBlank() }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    var uiState: AuthUiState by mutableStateOf(AuthUiState())
        private set

    init {
        viewModelScope.launch {
            repository.bootstrap()
            refreshProfile()
        }
    }

    fun onUsernameChange(value: String) {
        uiState = uiState.copy(username = value)
    }

    fun onPasswordChange(value: String) {
        uiState = uiState.copy(password = value)
    }

    fun onEmailChange(value: String) {
        uiState = uiState.copy(email = value)
    }

    fun onNicknameChange(value: String) {
        uiState = uiState.copy(nickname = value)
    }

    fun toggleMode() {
        uiState = uiState.copy(isRegisterMode = !uiState.isRegisterMode)
    }

    fun login() {
        viewModelScope.launch {
            uiState = uiState.copy(isLoading = true, error = null)
            val result = repository.login(uiState.username, uiState.password)
            uiState = if (result.isSuccess) {
                uiState.copy(isLoading = false, user = result.getOrNull())
            } else {
                uiState.copy(isLoading = false, error = result.exceptionOrNull()?.message)
            }
        }
    }

    fun register() {
        viewModelScope.launch {
            uiState = uiState.copy(isLoading = true, error = null)
            val result = repository.register(
                uiState.username,
                uiState.email,
                uiState.password,
                uiState.nickname
            )
            if (result.isSuccess) {
                login()
            } else {
                uiState = uiState.copy(isLoading = false, error = result.exceptionOrNull()?.message)
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            repository.logout()
            uiState = AuthUiState()
        }
    }

    fun refreshProfile() {
        viewModelScope.launch {
            val result = repository.profile()
            if (result.isSuccess) {
                uiState = uiState.copy(user = result.getOrNull(), error = null)
            } else {
                uiState = uiState.copy(error = result.exceptionOrNull()?.message)
            }
        }
    }
}
