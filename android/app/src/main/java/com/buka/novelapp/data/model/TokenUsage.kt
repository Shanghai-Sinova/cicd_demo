package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.math.ceil

@Serializable
data class TokenUsageDto(
    @SerialName("prompt_tokens") val promptTokens: Int = 0,
    @SerialName("completion_tokens") val completionTokens: Int = 0,
    @SerialName("total_tokens") val totalTokens: Int = 0
)

data class TokenUsageEstimate(
    val promptTokens: Int,
    val completionTokens: Int,
    val totalTokens: Int
)

object TokenEstimator {
    fun estimate(text: String, expectedCompletionTokens: Int = 0): TokenUsageEstimate {
        val normalized = text.trim()
        val prompt = ceil(normalized.length / 4.0).toInt().coerceAtLeast(1)
        val completion = expectedCompletionTokens.coerceAtLeast(0)
        return TokenUsageEstimate(prompt, completion, prompt + completion)
    }

    fun estimateForBranches(theme: String, branches: List<String>, expectedCompletionTokens: Int = 0): TokenUsageEstimate {
        val input = buildString {
            append(theme.trim())
            branches.filter { it.isNotBlank() }.forEach {
                append('\n')
                append(it.trim())
            }
        }
        return estimate(input, expectedCompletionTokens)
    }
}
