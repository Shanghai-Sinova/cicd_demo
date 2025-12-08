package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.buka.novelapp.data.model.ProjectDto
import com.buka.novelapp.ui.viewmodel.ProjectsViewModel

@Composable
fun ProjectsScreen(viewModel: ProjectsViewModel) {
    LaunchedEffect(Unit) { viewModel.fetchProjects() }

    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        OutlinedTextField(
            value = viewModel.search,
            onValueChange = {
                viewModel.updateSearch(it)
                viewModel.fetchProjects()
            },
            label = { Text("搜索项目") },
            modifier = Modifier.fillMaxWidth()
        )
        FilterRow(viewModel)
        OutlinedTextField(
            value = viewModel.newProjectName,
            onValueChange = { viewModel.newProjectName = it },
            label = { Text("新项目名称") },
            modifier = Modifier.fillMaxWidth()
        )
        OutlinedTextField(
            value = viewModel.newProjectIdea,
            onValueChange = { viewModel.newProjectIdea = it },
            label = { Text("灵感 (可选)") },
            modifier = Modifier.fillMaxWidth()
        )
        Button(onClick = { viewModel.createProject() }, enabled = viewModel.newProjectName.isNotBlank()) {
            Text("新建项目")
        }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(viewModel.projects) { project ->
                ProjectItem(project, onFavorite = { viewModel.toggleFavorite(project) }) {
                    viewModel.delete(project)
                }
            }
        }
    }
}

@Composable
private fun FilterRow(viewModel: ProjectsViewModel) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        listOf(null to "全部", "in_progress" to "进行中", "completed" to "已完成", "archived" to "归档")
            .forEach { (value, label) ->
                FilterChip(
                    selected = viewModel.statusFilter == value,
                    onClick = { viewModel.applyStatusFilter(value) },
                    label = { Text(label) },
                    colors = FilterChipDefaults.filterChipColors()
                )
            }
    }
}

@Composable
private fun ProjectItem(project: ProjectDto, onFavorite: () -> Unit, onDelete: () -> Unit) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(project.projectName)
            Text(project.storyCore ?: "暂无故事核心")
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                TextButton(onClick = onFavorite) { Text(if (project.isFavorite == true) "取消收藏" else "收藏") }
                TextButton(onClick = onDelete) { Text("删除") }
            }
        }
    }
}
