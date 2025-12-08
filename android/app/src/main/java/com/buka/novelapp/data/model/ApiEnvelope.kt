@file:OptIn(InternalSerializationApi::class)
package com.buka.novelapp.data.model

import kotlinx.serialization.InternalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ApiEnvelope<T>(
    val success: Boolean? = null,
    val message: String? = null,
    val code: Int? = null,
    val data: T? = null
)

@Serializable
data class Pagination(
    val page: Int = 1,
    val limit: Int = 20,
    val total: Int = 0,
    @SerialName("total_pages") val totalPages: Int? = null
)
