package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.buka.novelapp.data.model.ProjectDto
import com.buka.novelapp.ui.viewmodel.HomeViewModel

@Composable
fun HomeScreen(viewModel: HomeViewModel, onStartCreation: () -> Unit) {
    LazyColumn(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Column {
                Text(text = "欢迎回来", style = MaterialTheme.typography.titleLarge)
                Text(text = "继续你的创作旅程", style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = { viewModel.load() }) {
                    Text("刷新数据")
                }
            }
        }
        item { StatsSection(viewModel) }
        item { QuickActions(onStart = onStartCreation) }
        item { Text("最新项目", style = MaterialTheme.typography.titleMedium) }
        items(viewModel.projects.take(4)) { ProjectCard(it) }
    }
}

@Composable
private fun StatsSection(viewModel: HomeViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(
                title = "项目",
                value = viewModel.stats.total.toString(),
                modifier = Modifier.weight(1f)
            )
            StatCard(
                title = "进行中",
                value = viewModel.stats.active.toString(),
                modifier = Modifier.weight(1f)
            )
        }
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(
                title = "已完成",
                value = viewModel.stats.completed.toString(),
                modifier = Modifier.weight(1f)
            )
            StatCard(
                title = "字数",
                value = "${viewModel.stats.words} 字",
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun StatCard(title: String, value: String, modifier: Modifier = Modifier) {
    Card(elevation = CardDefaults.cardElevation(defaultElevation = 2.dp), modifier = modifier) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(title, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            Text(value, style = MaterialTheme.typography.titleLarge)
        }
    }
}

@Composable
private fun QuickActions(onStart: () -> Unit) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("快速操作", style = MaterialTheme.typography.titleMedium)
            Button(onClick = onStart) { Text("开始生成灵感") }
        }
    }
}

@Composable
private fun ProjectCard(project: ProjectDto) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(project.projectName, style = MaterialTheme.typography.titleMedium)
            Text(project.storyCore ?: "尚未生成", style = MaterialTheme.typography.bodySmall)
        }
    }
}
