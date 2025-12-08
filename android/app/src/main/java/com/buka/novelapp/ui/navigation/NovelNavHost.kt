package com.buka.novelapp.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.buka.novelapp.ui.screen.LoginScreen
import com.buka.novelapp.ui.screen.MainScreen
import com.buka.novelapp.ui.viewmodel.AuthViewModel
import com.buka.novelapp.ui.viewmodel.ViewModelFactory

private const val ROUTE_AUTH = "auth"
private const val ROUTE_MAIN = "main"

@Composable
fun NovelNavHost(factory: ViewModelFactory, navController: NavHostController = rememberNavController()) {
    val authViewModel: AuthViewModel = viewModel(factory = factory)
    val hasToken by authViewModel.hasToken.collectAsStateWithLifecycle()
    val isLoggedIn = hasToken || authViewModel.uiState.user != null

    LaunchedEffect(isLoggedIn) {
        navController.navigate(if (isLoggedIn) ROUTE_MAIN else ROUTE_AUTH) {
            popUpTo(0)
        }
    }

    NavHost(navController = navController, startDestination = if (isLoggedIn) ROUTE_MAIN else ROUTE_AUTH) {
        composable(ROUTE_AUTH) {
            LoginScreen(
                state = authViewModel.uiState,
                onUsernameChange = authViewModel::onUsernameChange,
                onPasswordChange = authViewModel::onPasswordChange,
                onEmailChange = authViewModel::onEmailChange,
                onNicknameChange = authViewModel::onNicknameChange,
                onToggleMode = authViewModel::toggleMode,
                onLogin = authViewModel::login,
                onRegister = authViewModel::register
            )
        }
        composable(ROUTE_MAIN) {
            MainScreen(factory = factory, onLogout = authViewModel::logout)
        }
    }
}
