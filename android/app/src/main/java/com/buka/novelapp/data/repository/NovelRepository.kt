package com.buka.novelapp.data.repository

import com.buka.novelapp.data.model.ApiEnvelope
import com.buka.novelapp.data.model.BrainstormRequest
import com.buka.novelapp.data.model.BrainstormResponse
import com.buka.novelapp.data.model.CreatePaymentOrderDto
import com.buka.novelapp.data.model.LoginRequest
import com.buka.novelapp.data.model.LoginResult
import com.buka.novelapp.data.model.MediaGenerateResponse
import com.buka.novelapp.data.model.MultiNarrativeBranchInput
import com.buka.novelapp.data.model.MediaGenerateRequest
import com.buka.novelapp.data.model.MultiNarrativePayload
import com.buka.novelapp.data.model.MultiNarrativeRequest
import com.buka.novelapp.data.model.PaymentPlanListDto
import com.buka.novelapp.data.model.PointsBalanceDto
import com.buka.novelapp.data.model.ProjectDto
import com.buka.novelapp.data.model.ProjectsPayload
import com.buka.novelapp.data.model.ProtagonistResponse
import com.buka.novelapp.data.model.RegisterRequest
import com.buka.novelapp.data.model.SequenceBeatResponse
import com.buka.novelapp.data.model.SequenceScriptResponse
import com.buka.novelapp.data.model.StoryCoreAdvanceRequest
import com.buka.novelapp.data.model.TransactionHistoryDto
import com.buka.novelapp.data.model.UserDto
import com.buka.novelapp.data.model.MemoryCompassRequest
import com.buka.novelapp.data.model.MemoryCompassPayload
import com.buka.novelapp.data.network.ApiClient
import com.buka.novelapp.data.network.NovelApi
import com.buka.novelapp.data.storage.AuthStorage
import kotlinx.coroutines.flow.Flow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject

class NovelRepository(
    private val apiClient: ApiClient,
    private val authStorage: AuthStorage
) {
    private val api: NovelApi = apiClient.api
    private val mediaType = "application/json".toMediaType()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true; explicitNulls = false }

    val tokenFlow: Flow<String?> = authStorage.tokenFlow

    suspend fun bootstrap() {
        apiClient.hydrateToken()
    }

    suspend fun login(username: String, password: String): Result<UserDto> = runCatching {
        val envelope: ApiEnvelope<LoginResult> = api.login(LoginRequest(username, password))
        val data = envelope.data ?: throw IllegalStateException(envelope.message ?: "登录失败")
        authStorage.saveToken(data.token)
        apiClient.setToken(data.token)
        data.user
    }

    suspend fun profile(): Result<UserDto> = runCatching {
        val envelope = api.profile()
        envelope.data ?: throw IllegalStateException("无法获取用户信息")
    }

    suspend fun register(username: String, email: String, password: String, nickname: String?): Result<UserDto> = runCatching {
        val response = api.register(RegisterRequest(username, email, password, nickname))
        response.data ?: throw IllegalStateException(response.message ?: "注册失败")
    }

    suspend fun logout() {
        authStorage.clear()
        apiClient.setToken(null)
    }

    suspend fun fetchProjects(search: String?, status: String?): Result<ProjectsPayload> = runCatching {
        val response = api.getProjects(search = search, status = status)
        response.data ?: throw IllegalStateException("项目列表为空")
    }

    suspend fun createProject(name: String, idea: String?): Result<ProjectDto> = runCatching {
        val payload = mutableMapOf<String, Any>("project_name" to name)
        if (!idea.isNullOrBlank()) {
            payload["first_idea"] = idea
        }
        val body = payload.toRequestBody(mediaType)
        val response = api.createProject(body)
        response.data ?: throw IllegalStateException("创建失败")
    }

    suspend fun updateProject(projectId: String, fields: Map<String, Any?>): Result<ProjectDto> = runCatching {
        val body = fields.toRequestBody(mediaType)
        val response = api.updateProject(projectId, body)
        response.data ?: throw IllegalStateException("更新失败")
    }

    suspend fun deleteProject(projectId: String) {
        api.deleteProject(projectId)
    }

    suspend fun fetchProject(projectId: String): Result<ProjectDto> = runCatching {
        val response = api.getProject(projectId)
        response.data ?: throw IllegalStateException("未找到项目")
    }

    suspend fun generateBrainstorm(request: BrainstormRequest): BrainstormResponse = api.generateBrainstorm(request)

    suspend fun advanceStoryCore(projectId: String, storyCore: String) {
        api.advanceStoryCore(projectId, StoryCoreAdvanceRequest(projectId, storyCore, 1))
    }

    suspend fun generateProtagonist(projectId: String): ProtagonistResponse {
        val payload = mapOf(
            "project_id" to projectId,
            "leading_quantity" to 1
        ).toRequestBody(mediaType)
        return api.generateProtagonist(projectId, payload)
    }

    suspend fun generateSupporting(projectId: String) = api.generateSupporting(projectId)

    suspend fun generatePlot(projectId: String) = api.generatePlot(mapOf("project_id" to projectId).toRequestBody(mediaType))

    suspend fun generateBeats(projectId: String, sequenceId: String) = api.generateBeats(
        mapOf("project_id" to projectId, "sequence_id" to sequenceId).toRequestBody(mediaType)
    )

    suspend fun generateScripts(projectId: String, beats: List<String>): SequenceScriptResponse {
        val variables = JSONObject().apply {
            put("project_id", projectId)
            put("current_seq_beats", JSONArray(beats))
        }
        val metadata = JSONObject(mapOf("project_id" to projectId))
        val root = JSONObject().apply {
            put("template_name", "sequence_scripts")
            put("variables", variables)
            put("metadata", metadata)
        }
        val body = root.toString().toRequestBody(mediaType)
        return api.generateScripts(body)
    }

    suspend fun generateMemoryCompass(projectId: String, focus: String, anchors: List<String>): Result<MemoryCompassPayload> = runCatching {
        val request = MemoryCompassRequest(projectId = projectId, focus = focus, anchors = anchors)
        val body = json.encodeToString(MemoryCompassRequest.serializer(), request).toRequestBody(mediaType)
        val response = api.generateMemoryCompass(body)
        if (response.success == false) throw IllegalStateException(response.message ?: "记忆罗盘生成失败")
        response.data ?: MemoryCompassPayload()
    }

    suspend fun generateImage(prompt: String, style: String?): Result<MediaGenerateResponse> = runCatching {
        val payload = MediaGenerateRequest(prompt = prompt, style = style)
        val body = json.encodeToString(MediaGenerateRequest.serializer(), payload).toRequestBody(mediaType)
        val response = api.generateImage(body)
        if (response.success == false) throw IllegalStateException(response.message ?: "图片生成失败")
        response
    }

    suspend fun generateVideo(prompt: String, seconds: Int): Result<MediaGenerateResponse> = runCatching {
        val payload = MediaGenerateRequest(prompt = prompt, seconds = seconds)
        val body = json.encodeToString(MediaGenerateRequest.serializer(), payload).toRequestBody(mediaType)
        val response = api.generateVideo(body)
        if (response.success == false) throw IllegalStateException(response.message ?: "视频生成失败")
        response
    }

    suspend fun generateMultiNarrative(
        projectId: String,
        theme: String,
        branches: List<MultiNarrativeBranchInput>,
        maxTokens: Int?
    ): Result<MultiNarrativePayload> = runCatching {
        val request = MultiNarrativeRequest(projectId = projectId, theme = theme, branches = branches, maxTokens = maxTokens)
        val body = json.encodeToString(MultiNarrativeRequest.serializer(), request).toRequestBody(mediaType)
        val response = api.generateMultiNarrative(body)
        if (response.success == false) throw IllegalStateException(response.message ?: "多线叙事失败")
        response.data ?: MultiNarrativePayload()
    }

    suspend fun fetchPoints(): Result<PointsBalanceDto> = runCatching {
        val response = api.getPoints()
        response.data ?: throw IllegalStateException("积分数据为空")
    }

    suspend fun fetchTransactions(): Result<TransactionHistoryDto> = runCatching {
        val response = api.getPointTransactions()
        response.data ?: throw IllegalStateException("交易数据为空")
    }

    suspend fun fetchPaymentPlans(): Result<PaymentPlanListDto> = runCatching {
        val response = api.getPaymentPlans()
        response.data ?: throw IllegalStateException("套餐为空")
    }

    suspend fun createPaymentOrder(planId: String, channel: String): Result<CreatePaymentOrderDto> = runCatching {
        val payload = mapOf("plan_id" to planId, "channel" to channel).toRequestBody(mediaType)
        val response = api.createPaymentOrder(payload)
        response.data ?: throw IllegalStateException("订单创建失败")
    }
}

private fun Map<String, Any?>.toRequestBody(mediaType: okhttp3.MediaType) : RequestBody {
    val json = JSONObject()
    forEach { (key, value) ->
        when (value) {
            null -> json.put(key, JSONObject.NULL)
            is Iterable<*> -> json.put(key, JSONArray(value.map { it }))
            else -> json.put(key, value)
        }
    }
    return json.toString().toRequestBody(mediaType)
}
