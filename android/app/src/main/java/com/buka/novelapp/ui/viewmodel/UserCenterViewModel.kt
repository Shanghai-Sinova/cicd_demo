package com.buka.novelapp.ui.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buka.novelapp.data.model.PaymentPlanDto
import com.buka.novelapp.data.model.PaymentPointsTierDto
import com.buka.novelapp.data.model.PaymentPriceDto
import com.buka.novelapp.data.model.PaymentPlanListDto
import com.buka.novelapp.data.model.PointsBalanceDto
import com.buka.novelapp.data.model.PointsTransactionDto
import com.buka.novelapp.data.repository.NovelRepository
import kotlinx.coroutines.launch

class UserCenterViewModel(private val repository: NovelRepository) : ViewModel() {
    var pointsState by mutableStateOf<PointsBalanceDto?>(null)
        private set
    var transactions by mutableStateOf<List<PointsTransactionDto>>(emptyList())
        private set
    var plans by mutableStateOf<List<PaymentPlanDto>>(emptyList())
        private set
    var tiers by mutableStateOf<List<PaymentPointsTierDto>>(emptyList())
        private set
    var selectedChannel by mutableStateOf("alipay_page")
    var credentialUrl by mutableStateOf<String?>(null)
    var qrContent by mutableStateOf<String?>(null)
    var error by mutableStateOf<String?>(null)
    var loading by mutableStateOf(false)

    fun refresh() {
        viewModelScope.launch { loadPoints() }
        viewModelScope.launch { loadTransactions() }
        viewModelScope.launch { loadPlans() }
    }

    fun loadPoints() {
        viewModelScope.launch {
            loading = true
            error = null
            val result = repository.fetchPoints()
            if (result.isSuccess) {
                pointsState = result.getOrNull()
            } else {
                error = result.exceptionOrNull()?.message
            }
            loading = false
        }
    }

    fun loadTransactions() {
        viewModelScope.launch {
            val result = repository.fetchTransactions()
            if (result.isSuccess) {
                transactions = result.getOrNull()?.transactions ?: emptyList()
            }
        }
    }

    fun loadPlans() {
        viewModelScope.launch {
            val result = repository.fetchPaymentPlans()
            if (result.isSuccess) {
                val payload: PaymentPlanListDto? = result.getOrNull()
                plans = payload?.plans ?: emptyList()
                tiers = payload?.pointsTiers ?: emptyList()
            } else {
                error = result.exceptionOrNull()?.message
            }
        }
    }

    fun createOrder(planId: String) {
        viewModelScope.launch {
            loading = true
            error = null
            val result = repository.createPaymentOrder(planId, selectedChannel)
            if (result.isSuccess) {
                val credential = result.getOrNull()?.credential
                credentialUrl = credential?.alipayPage?.pageUrl
                qrContent = credential?.wechatNative?.codeUrl
            } else {
                error = result.exceptionOrNull()?.message
            }
            loading = false
        }
    }
}
