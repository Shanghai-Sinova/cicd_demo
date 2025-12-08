package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LibraryBooks
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.buka.novelapp.ui.viewmodel.CreationStepKind
import com.buka.novelapp.ui.viewmodel.CreationViewModel
import com.buka.novelapp.ui.viewmodel.HomeViewModel
import com.buka.novelapp.ui.viewmodel.MultiNarrativeViewModel
import com.buka.novelapp.ui.viewmodel.MemoryCompassViewModel
import com.buka.novelapp.ui.viewmodel.ProjectsViewModel
import com.buka.novelapp.ui.viewmodel.UserCenterViewModel
import com.buka.novelapp.ui.viewmodel.ViewModelFactory

private enum class MainTab(val label: String) {
    HOME("首页"),
    PROJECTS("项目"),
    CREATION("创作"),
    PROFILE("我的")
}

@Composable
fun MainScreen(factory: ViewModelFactory, onLogout: () -> Unit) {
    val homeViewModel: HomeViewModel = viewModel(factory = factory)
    val projectsViewModel: ProjectsViewModel = viewModel(factory = factory)
    val creationViewModel: CreationViewModel = viewModel(factory = factory)
    val multiNarrativeViewModel: MultiNarrativeViewModel = viewModel(factory = factory)
    val memoryCompassViewModel: MemoryCompassViewModel = viewModel(factory = factory)
    val userCenterViewModel: UserCenterViewModel = viewModel(factory = factory)

    var currentTab by remember { mutableStateOf(MainTab.HOME) }

    LaunchedEffect(Unit) {
        homeViewModel.load()
        projectsViewModel.load()
    }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = currentTab == MainTab.HOME,
                    onClick = { currentTab = MainTab.HOME },
                    icon = { androidx.compose.material3.Icon(Icons.Default.Home, contentDescription = null) },
                    label = { Text(MainTab.HOME.label) },
                    colors = NavigationBarItemDefaults.colors()
                )
                NavigationBarItem(
                    selected = currentTab == MainTab.PROJECTS,
                    onClick = { currentTab = MainTab.PROJECTS },
                    icon = { androidx.compose.material3.Icon(Icons.Default.LibraryBooks, contentDescription = null) },
                    label = { Text(MainTab.PROJECTS.label) }
                )
                NavigationBarItem(
                    selected = currentTab == MainTab.CREATION,
                    onClick = { currentTab = MainTab.CREATION },
                    icon = { androidx.compose.material3.Icon(Icons.Default.AutoStories, contentDescription = null) },
                    label = { Text(MainTab.CREATION.label) }
                )
                NavigationBarItem(
                    selected = currentTab == MainTab.PROFILE,
                    onClick = { currentTab = MainTab.PROFILE },
                    icon = { androidx.compose.material3.Icon(Icons.Default.Person, contentDescription = null) },
                    label = { Text(MainTab.PROFILE.label) }
                )
            }
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            when (currentTab) {
                MainTab.HOME -> HomeScreen(homeViewModel) {
                    creationViewModel.runStep(CreationStepKind.INSPIRATION)
                }
                MainTab.PROJECTS -> ProjectsScreen(projectsViewModel)
                MainTab.CREATION -> CreationScreen(creationViewModel, multiNarrativeViewModel, memoryCompassViewModel)
                MainTab.PROFILE -> ProfileScreen(onLogout = onLogout, userCenterViewModel = userCenterViewModel)
            }
        }
    }
}
