package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.buka.novelapp.ui.viewmodel.UserCenterViewModel

private sealed class ProfilePage {
    data object Main : ProfilePage()
    data class Payment(val fromChannel: String) : ProfilePage()
}

private data class PaymentOption(
    val title: String,
    val description: String,
    val tag: String
)

@Composable
fun ProfileScreen(onLogout: () -> Unit, userCenterViewModel: UserCenterViewModel) {
    LaunchedEffect(true) { userCenterViewModel.refresh() }
    val pageState = remember { mutableStateOf<ProfilePage>(ProfilePage.Main) }

    when (val page = pageState.value) {
        ProfilePage.Main -> ProfileMainContent(
            viewModel = userCenterViewModel,
            onLogout = onLogout,
            onNavigatePayment = { from -> pageState.value = ProfilePage.Payment(from) }
        )

        is ProfilePage.Payment -> PaymentMethodListScreen(
            selectedChannel = page.fromChannel,
            onBack = { pageState.value = ProfilePage.Main },
            onSelect = { option ->
                userCenterViewModel.selectedChannel = if (option.tag.contains("wechat")) "wechat_native" else "alipay_page"
                pageState.value = ProfilePage.Main
            }
        )
    }
}

@Composable
private fun ProfileMainContent(
    viewModel: UserCenterViewModel,
    onLogout: () -> Unit,
    onNavigatePayment: (String) -> Unit
) {
    LazyColumn(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item {
            Card {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("个人中心")
                    Text("管理积分与充值，保持与 Web 一致体验")
                }
            }
        }
        item { PointsCard(viewModel) }
        item { TransactionsCard(viewModel) }
        item { RechargeCard(viewModel, onNavigatePayment) }
        item {
            Button(onClick = onLogout, modifier = Modifier.fillMaxWidth()) {
                Text("退出登录")
            }
        }
    }
}

@Composable
private fun PointsCard(viewModel: UserCenterViewModel) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("积分概览")
            val points = viewModel.pointsState
            if (points == null) {
                Text("加载中…")
            } else {
                Text("可用积分：${points.usablePoints}")
                Text("等级：${points.levelName}")
            }
            OutlinedButton(onClick = { viewModel.loadPoints() }) {
                Text("刷新")
            }
        }
    }
}

@Composable
private fun TransactionsCard(viewModel: UserCenterViewModel) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("最近积分流水")
            val list = viewModel.transactions.take(5)
            if (list.isEmpty()) {
                Text("暂无记录")
            } else {
                list.forEach {
                    Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                        Column {
                            Text(it.reason)
                            Text(it.status)
                        }
                        Text(if (it.amount > 0) "+${it.amount}" else "${it.amount}")
                    }
                }
            }
        }
    }
}

@Composable
private fun RechargeCard(viewModel: UserCenterViewModel, onNavigatePayment: (String) -> Unit) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("充值 / 会员")
            ChannelSelector(viewModel, onNavigatePayment)
            viewModel.plans.forEach { plan ->
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(plan.name)
                    Text(plan.description)
                    Button(onClick = { viewModel.createOrder(plan.planId) }) {
                        Text("购买 ${plan.price.amountFormatted}")
                    }
                }
            }
            viewModel.credentialUrl?.let {
                Text("支付宝链接：$it")
            }
            viewModel.qrContent?.let {
                Text("微信扫码链接：$it")
            }
        }
    }
}

@Composable
private fun ChannelSelector(viewModel: UserCenterViewModel, onNavigatePayment: (String) -> Unit) {
    val expanded = remember { mutableStateOf(false) }
    OutlinedButton(onClick = { expanded.value = true }) {
        Text(if (viewModel.selectedChannel == "alipay_page") "支付宝支付" else "微信扫码支付")
    }
    DropdownMenu(expanded = expanded.value, onDismissRequest = { expanded.value = false }) {
        DropdownMenuItem(text = { Text("支付宝页面") }, onClick = {
            viewModel.selectedChannel = "alipay_page"
            expanded.value = false
            onNavigatePayment("alipay_page")
        })
        DropdownMenuItem(text = { Text("微信扫码") }, onClick = {
            viewModel.selectedChannel = "wechat_native"
            expanded.value = false
            onNavigatePayment("wechat_native")
        })
    }
}

@Composable
private fun PaymentMethodListScreen(
    selectedChannel: String,
    onBack: () -> Unit,
    onSelect: (PaymentOption) -> Unit
) {
    val options = remember {
        listOf(
            PaymentOption("云闪付", "支持主流银行卡快速付款", "unionpay"),
            PaymentOption("微信支付", "微信内调起 / 扫码均可", "wechat_standard"),
            PaymentOption("支付宝喷一碰", "NFC 轻触即可完成支付", "alipay_tap"),
            PaymentOption("支付宝支付", "常规扫码或 App 内支付", "alipay_standard")
        )
    }

    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("选择支付方式")
                Text("当前渠道：${if (selectedChannel == "alipay_page") "支付宝" else "微信"}")
            }
            OutlinedButton(onClick = onBack) { Text("返回") }
        }

        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(options) { option ->
                Card {
                    Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(option.title)
                        Text(option.description)
                        Button(onClick = { onSelect(option) }) {
                            Text("立即使用")
                        }
                    }
                }
            }
        }
    }
}
