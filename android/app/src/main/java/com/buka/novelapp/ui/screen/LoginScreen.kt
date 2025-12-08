package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.buka.novelapp.ui.viewmodel.AuthUiState

@Composable
fun LoginScreen(
    state: AuthUiState,
    onUsernameChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onEmailChange: (String) -> Unit,
    onNicknameChange: (String) -> Unit,
    onToggleMode: () -> Unit,
    onLogin: () -> Unit,
    onRegister: () -> Unit
) {
    Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("AI 创作工作台")
        OutlinedTextField(
            value = state.username,
            onValueChange = onUsernameChange,
            label = { Text("用户名") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = state.password,
            onValueChange = onPasswordChange,
            label = { Text("密码") },
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth()
        )
        if (state.isRegisterMode) {
            OutlinedTextField(
                value = state.email,
                onValueChange = onEmailChange,
                label = { Text("邮箱") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = state.nickname,
                onValueChange = onNicknameChange,
                label = { Text("昵称") },
                modifier = Modifier.fillMaxWidth()
            )
        }
        if (state.error != null) {
            Text(state.error, color = androidx.compose.ui.graphics.Color.Red)
        }
        Button(
            onClick = { if (state.isRegisterMode) onRegister() else onLogin() },
            enabled = !state.isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(if (state.isRegisterMode) "注册并登录" else "登录")
        }
        TextButton(onClick = onToggleMode) {
            Text(if (state.isRegisterMode) "已有账号？切换登录" else "没有账号？注册")
        }
        TextButton(onClick = onLogin, enabled = !state.isLoading && !state.isRegisterMode) {
            Text("使用示例账号自动登录")
        }
    }
}
