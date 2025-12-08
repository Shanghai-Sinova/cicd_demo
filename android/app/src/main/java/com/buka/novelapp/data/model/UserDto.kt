package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class LoginRequest(
    val username: String,
    val password: String
)

@Serializable
data class LoginResult(
    val token: String,
    @SerialName("expires_at") val expiresAt: String,
    val user: UserDto
)

@Serializable
data class UserDto(
    val id: Int,
    val username: String,
    val email: String? = null,
    val role: String? = null,
    val nickname: String? = null,
    val avatar: String? = null,
    @SerialName("is_approved") val isApproved: Boolean? = null,
    val status: String? = null
)
