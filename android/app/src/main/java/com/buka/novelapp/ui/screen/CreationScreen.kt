package com.buka.novelapp.ui.screen

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.buka.novelapp.data.model.StoryBranchDto
import com.buka.novelapp.ui.viewmodel.BranchFormState
import com.buka.novelapp.ui.viewmodel.CreationStepKind
import com.buka.novelapp.ui.viewmodel.CreationStepState
import com.buka.novelapp.ui.viewmodel.CreationViewModel
import com.buka.novelapp.ui.viewmodel.MultiNarrativeViewModel
import com.buka.novelapp.ui.viewmodel.MultiNarrativeUiState
import com.buka.novelapp.ui.viewmodel.MemoryCompassViewModel
import com.buka.novelapp.ui.viewmodel.StepStatus

private enum class CreationTab(val label: String) { WORKFLOW("创作流程"), MULTI("多线叙事"), MEMORY("记忆罗盘") }

@Composable
fun CreationScreen(creationViewModel: CreationViewModel, multiNarrativeViewModel: MultiNarrativeViewModel, memoryCompassViewModel: MemoryCompassViewModel) {
    var currentTab by remember { mutableStateOf(CreationTab.WORKFLOW) }
    Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = currentTab.ordinal) {
            CreationTab.values().forEach { tab ->
                Tab(selected = currentTab == tab, onClick = { currentTab = tab }, text = { Text(tab.label) })
            }
        }
        when (currentTab) {
            CreationTab.WORKFLOW -> CreationWorkflow(creationViewModel)
            CreationTab.MULTI -> MultiNarrativePanel(multiNarrativeViewModel)
            CreationTab.MEMORY -> MemoryCompassPanel(memoryCompassViewModel)
        }
    }
}

@Composable
private fun CreationWorkflow(viewModel: CreationViewModel) {
    LazyColumn(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        item { ProjectBindingSection(viewModel) }
        item { Text("创作步骤", style = MaterialTheme.typography.titleMedium) }
        items(viewModel.uiState.steps) { step ->
            StepCard(step = step, onRun = { viewModel.runStep(step.kind) })
        }
        item {
            if (viewModel.uiState.script.isNotBlank()) {
                OutputCard(title = "正文输出", content = viewModel.uiState.script)
            }
        }
    }
}

@Composable
private fun ProjectBindingSection(viewModel: CreationViewModel) {
    Card(elevation = CardDefaults.cardElevation(2.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedTextField(
                value = viewModel.uiState.projectId,
                onValueChange = viewModel::updateProjectId,
                label = { Text("项目ID") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = viewModel.uiState.projectName,
                onValueChange = viewModel::updateProjectName,
                label = { Text("项目名称") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = viewModel.uiState.firstIdea,
                onValueChange = viewModel::updateFirstIdea,
                label = { Text("创作灵感") },
                modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = viewModel::ensureProject) { Text("新建/绑定") }
                OutlinedButton(onClick = viewModel::attachProject) { Text("同步项目") }
            }
            viewModel.uiState.error?.let { Text(it, color = androidx.compose.ui.graphics.Color.Red) }
        }
    }
}

@Composable
private fun StepCard(step: CreationStepState, onRun: () -> Unit) {
    Card(elevation = CardDefaults.cardElevation(1.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(step.kind.title, style = MaterialTheme.typography.titleMedium)
            Text(step.kind.description, maxLines = 2, overflow = TextOverflow.Ellipsis)
            Text("状态：${step.status.name}")
            if (step.preview.isNotBlank()) {
                Text(step.preview, maxLines = 3, overflow = TextOverflow.Ellipsis)
            }
            Button(onClick = onRun) { Text("执行") }
        }
    }
}

@Composable
private fun OutputCard(title: String, content: String) {
    Card {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(content)
        }
    }
}

@Composable
private fun MultiNarrativePanel(viewModel: MultiNarrativeViewModel) {
    val state = viewModel.uiState
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item {
            Text("多线叙事生成与Token预估", style = MaterialTheme.typography.titleMedium)
        }
        item {
            Card(elevation = CardDefaults.cardElevation(1.dp)) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = state.projectId,
                        onValueChange = viewModel::updateProjectId,
                        label = { Text("项目ID（可选，便于关联项目）") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = state.theme,
                        onValueChange = viewModel::updateTheme,
                        label = { Text("主题 / 故事核心") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = state.targetTokens.toString(),
                        onValueChange = viewModel::updateTargetTokens,
                        label = { Text("预期输出Token上限") },
                        keyboardOptions = KeyboardOptions.Default.copy(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
        items(state.branches.size) { index ->
            BranchCard(index = index, branch = state.branches[index], onTitleChange = viewModel::updateBranchTitle, onGoalChange = viewModel::updateBranchGoal, onToneChange = viewModel::updateBranchTone, onRemove = viewModel::removeBranch)
        }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = viewModel::addBranch) { Text("新增分支") }
                FilledTonalButton(onClick = viewModel::generate, enabled = !state.isLoading) {
                    Text(if (state.isLoading) "生成中…" else "生成多线叙事")
                }
            }
            state.error?.let { Text(it, color = androidx.compose.ui.graphics.Color.Red, modifier = Modifier.padding(top = 8.dp)) }
        }
        item { TokenUsageCard(state) }
        if (state.results.isNotEmpty()) {
            item { Text("生成结果", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 4.dp)) }
            items(state.results) { branch ->
                StoryBranchCard(branch)
            }
        }
    }
}

@Composable
private fun BranchCard(
    index: Int,
    branch: BranchFormState,
    onTitleChange: (Int, String) -> Unit,
    onGoalChange: (Int, String) -> Unit,
    onToneChange: (Int, String) -> Unit,
    onRemove: (Int) -> Unit
) {
    Card(elevation = CardDefaults.cardElevation(1.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text("分支 ${index + 1}", style = MaterialTheme.typography.titleMedium)
                OutlinedButton(onClick = { onRemove(index) }) { Text("移除") }
            }
            OutlinedTextField(
                value = branch.title,
                onValueChange = { onTitleChange(index, it) },
                label = { Text("分支标题") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = branch.goal,
                onValueChange = { onGoalChange(index, it) },
                label = { Text("分支目标 / 冲突") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = branch.tone,
                onValueChange = { onToneChange(index, it) },
                label = { Text("叙事风格 / 口吻") },
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun TokenUsageCard(state: MultiNarrativeUiState) {
    Card(elevation = CardDefaults.cardElevation(1.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text("本地预估Token消耗", style = MaterialTheme.typography.titleMedium)
            Text("Prompt: ${state.estimated.promptTokens}，输出预期：${state.estimated.completionTokens}")
            Text("总计: ${state.estimated.totalTokens}")
            state.remoteUsage?.let {
                Spacer(modifier = Modifier.height(8.dp))
                Text("服务端反馈Token", style = MaterialTheme.typography.titleSmall)
                Text("Prompt: ${it.promptTokens}，Completion: ${it.completionTokens}，Total: ${it.totalTokens}")
            }
        }
    }
}

@Composable
private fun MemoryCompassPanel(viewModel: MemoryCompassViewModel) {
    val state = viewModel.uiState
    LazyColumn(modifier = Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("记忆罗盘 + 影像生成", style = MaterialTheme.typography.titleMedium) }
        item {
            Card(elevation = CardDefaults.cardElevation(1.dp)) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        value = state.projectId,
                        onValueChange = viewModel::updateProjectId,
                        label = { Text("项目ID（可选）") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = state.focus,
                        onValueChange = viewModel::updateFocus,
                        label = { Text("记忆焦点 / 主问题") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = state.anchorInput,
                            onValueChange = viewModel::updateAnchorInput,
                            label = { Text("锚点关键词") },
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedButton(onClick = viewModel::addAnchor) { Text("添加") }
                    }
                    if (state.anchors.isNotEmpty()) {
                        Text(state.anchors.joinToString("，"), style = MaterialTheme.typography.bodySmall)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        FilledTonalButton(onClick = viewModel::generateCompass, enabled = !state.isLoadingCompass) {
                            Text(if (state.isLoadingCompass) "生成中…" else "生成记忆罗盘")
                        }
                        OutlinedButton(onClick = { if (state.anchorInput.isNotBlank()) viewModel.addAnchor() }) { Text("快捷添加") }
                    }
                    state.compassError?.let { Text(it, color = androidx.compose.ui.graphics.Color.Red) }
                }
            }
        }
        if (state.nodes.isNotEmpty()) {
            item { Text("记忆罗盘节点", style = MaterialTheme.typography.titleMedium) }
            items(state.nodes) { node ->
                Card(elevation = CardDefaults.cardElevation(1.dp)) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(node.title, style = MaterialTheme.typography.titleMedium)
                        Text(node.summary)
                        node.relation?.let { Text("关联：$it", style = MaterialTheme.typography.bodySmall) }
                    }
                }
            }
        }
        item { MediaGenerateSection(viewModel) }
    }
}

@Composable
private fun MediaGenerateSection(viewModel: MemoryCompassViewModel) {
    val state = viewModel.uiState
    Card(elevation = CardDefaults.cardElevation(1.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("图片生成")
            OutlinedTextField(
                value = state.imagePrompt,
                onValueChange = viewModel::updateImagePrompt,
                label = { Text("图片提示词") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = state.imageStyle,
                onValueChange = viewModel::updateImageStyle,
                label = { Text("风格/镜头/色调（可选）") },
                modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                FilledTonalButton(onClick = viewModel::generateImage, enabled = !state.isLoadingImage) {
                    Text(if (state.isLoadingImage) "生成中…" else "生成图片")
                }
                state.imageAsset?.url?.let { Text("URL: $it", style = MaterialTheme.typography.bodySmall) }
            }
            state.imageError?.let { Text(it, color = androidx.compose.ui.graphics.Color.Red) }
            Text("视频生成")
            OutlinedTextField(
                value = state.videoPrompt,
                onValueChange = viewModel::updateVideoPrompt,
                label = { Text("视频提示词") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = state.videoSeconds.toString(),
                onValueChange = viewModel::updateVideoSeconds,
                label = { Text("时长（3-60秒）") },
                keyboardOptions = KeyboardOptions.Default.copy(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                FilledTonalButton(onClick = viewModel::generateVideo, enabled = !state.isLoadingVideo) {
                    Text(if (state.isLoadingVideo) "生成中…" else "生成视频")
                }
                state.videoAsset?.url?.let { Text("URL: $it", style = MaterialTheme.typography.bodySmall) }
            }
            state.videoError?.let { Text(it, color = androidx.compose.ui.graphics.Color.Red) }
        }
    }
}

@Composable
private fun StoryBranchCard(branch: StoryBranchDto) {
    Card(elevation = CardDefaults.cardElevation(1.dp)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(branch.branchTitle, style = MaterialTheme.typography.titleMedium)
            Text(branch.synopsis)
            branch.hook?.let { Text("亮点：$it") }
            branch.beatOutline?.let { beats ->
                if (beats.isNotEmpty()) {
                    Text("节拍纲要：")
                    beats.forEach { Text("- $it") }
                }
            }
        }
    }
}
