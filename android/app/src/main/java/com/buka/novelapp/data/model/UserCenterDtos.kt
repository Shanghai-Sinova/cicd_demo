package com.buka.novelapp.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class RegisterRequest(
    val username: String,
    val email: String,
    val password: String,
    val nickname: String? = null
)

@Serializable
data class PointsBalanceDto(
    @SerialName("user_id") val userId: String,
    @SerialName("total_points") val totalPoints: Int,
    @SerialName("usable_points") val usablePoints: Int,
    @SerialName("frozen_points") val frozenPoints: Int,
    @SerialName("lifetime_earned") val lifetimeEarned: Int,
    @SerialName("lifetime_spent") val lifetimeSpent: Int,
    val level: Int,
    @SerialName("level_name") val levelName: String,
    @SerialName("next_level_points") val nextLevelPoints: Int,
    @SerialName("level_progress") val levelProgress: Double
)

@Serializable
data class PointsTransactionDto(
    val id: String,
    @SerialName("user_id") val userId: String,
    val type: String,
    val amount: Int,
    val reason: String,
    val status: String,
    val description: String? = null,
    @SerialName("created_at") val createdAt: String
)

@Serializable
data class TransactionHistoryDto(
    val transactions: List<PointsTransactionDto> = emptyList()
)

@Serializable
data class PaymentPlanListDto(
    val plans: List<PaymentPlanDto> = emptyList(),
    @SerialName("points_tiers") val pointsTiers: List<PaymentPointsTierDto> = emptyList()
)

@Serializable
data class PaymentPlanDto(
    @SerialName("plan_id") val planId: String,
    val name: String,
    val tier: String,
    @SerialName("tier_label") val tierLabel: String,
    val description: String,
    @SerialName("duration_days") val durationDays: Int,
    @SerialName("points_bonus") val pointsBonus: Int,
    val price: PaymentPriceDto,
    val badge: String? = null,
    val popular: Boolean = false,
    val features: List<String>? = null
)

@Serializable
data class PaymentPointsTierDto(
    val tier: String,
    @SerialName("tier_label") val tierLabel: String,
    val points: Int,
    @SerialName("price_label") val priceLabel: String,
    val multiplier: Double
)

@Serializable
data class PaymentPriceDto(
    @SerialName("amount_formatted") val amountFormatted: String,
    val currency: String
)

@Serializable
data class PaymentOrderViewDto(
    @SerialName("order_no") val orderNo: String,
    @SerialName("plan_name") val planName: String,
    @SerialName("plan_tier") val planTier: String,
    val channel: String,
    val status: String,
    @SerialName("points_bonus") val pointsBonus: Int,
    val amount: PaymentPriceDto
)

@Serializable
data class PaymentCredentialDto(
    val channel: String,
    val display: String,
    @SerialName("alipay_page") val alipayPage: AlipayPageCredentialDto? = null,
    @SerialName("wechat_native") val wechatNative: WechatNativeCredentialDto? = null
)

@Serializable
data class AlipayPageCredentialDto(
    @SerialName("page_url") val pageUrl: String
)

@Serializable
data class WechatNativeCredentialDto(
    @SerialName("code_url") val codeUrl: String
)

@Serializable
data class CreatePaymentOrderDto(
    val order: PaymentOrderViewDto,
    val credential: PaymentCredentialDto
)
