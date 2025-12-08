package com.buka.novelapp.data.network

import com.buka.novelapp.data.model.ApiEnvelope
import com.buka.novelapp.data.model.BrainstormRequest
import com.buka.novelapp.data.model.BrainstormResponse
import com.buka.novelapp.data.model.CreatePaymentOrderDto
import com.buka.novelapp.data.model.GenerateResponse
import com.buka.novelapp.data.model.LoginRequest
import com.buka.novelapp.data.model.LoginResult
import com.buka.novelapp.data.model.MediaGenerateResponse
import com.buka.novelapp.data.model.MemoryCompassResponse
import com.buka.novelapp.data.model.MultiNarrativeResponse
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
import okhttp3.RequestBody
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

interface NovelApi {
    @POST("auth/register")
    suspend fun register(@Body body: RegisterRequest): ApiEnvelope<UserDto>

    @POST("auth/login")
    suspend fun login(@Body body: LoginRequest): ApiEnvelope<LoginResult>

    @GET("auth/profile")
    suspend fun profile(): ApiEnvelope<UserDto>

    @GET("projects")
    suspend fun getProjects(
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20,
        @Query("status") status: String? = null,
        @Query("search") search: String? = null,
        @Query("sort_by") sortBy: String? = "updated_at",
        @Query("sort_order") sortOrder: String? = "desc"
    ): ApiEnvelope<ProjectsPayload>

    @POST("projects")
    suspend fun createProject(@Body body: RequestBody): ApiEnvelope<ProjectDto>

    @PUT("projects/{id}")
    suspend fun updateProject(@Path("id") id: String, @Body body: RequestBody): ApiEnvelope<ProjectDto>

    @DELETE("projects/{id}")
    suspend fun deleteProject(@Path("id") id: String): ApiEnvelope<Unit>

    @GET("projects/{id}")
    suspend fun getProject(@Path("id") id: String): ApiEnvelope<ProjectDto>

    @POST("llm/brainstorm")
    suspend fun generateBrainstorm(@Body body: BrainstormRequest): BrainstormResponse

    @POST("projects/{id}/story-core/advance")
    suspend fun advanceStoryCore(@Path("id") id: String, @Body body: StoryCoreAdvanceRequest): ApiEnvelope<Unit>

    @POST("protagonist/generate")
    suspend fun generateProtagonist(
        @Query("project_id") projectId: String,
        @Body body: RequestBody
    ): ProtagonistResponse

    @POST("projects/{id}/generate/supporting")
    suspend fun generateSupporting(@Path("id") id: String): GenerateResponse

    @POST("sequence-act/generate")
    suspend fun generatePlot(@Body body: RequestBody): GenerateResponse

    @POST("sequence-beat/generate")
    suspend fun generateBeats(@Body body: RequestBody): SequenceBeatResponse

    @POST("llm/generate-universal")
    suspend fun generateScripts(@Body body: RequestBody): SequenceScriptResponse

    @POST("llm/multi-narrative")
    suspend fun generateMultiNarrative(@Body body: RequestBody): MultiNarrativeResponse

    @POST("memory/compass")
    suspend fun generateMemoryCompass(@Body body: RequestBody): MemoryCompassResponse

    @POST("media/image/generate")
    suspend fun generateImage(@Body body: RequestBody): MediaGenerateResponse

    @POST("media/video/generate")
    suspend fun generateVideo(@Body body: RequestBody): MediaGenerateResponse

    @GET("points/balance")
    suspend fun getPoints(): ApiEnvelope<PointsBalanceDto>

    @GET("points/transactions")
    suspend fun getPointTransactions(): ApiEnvelope<TransactionHistoryDto>

    @GET("payments/plans")
    suspend fun getPaymentPlans(): ApiEnvelope<PaymentPlanListDto>

    @POST("payments/orders")
    suspend fun createPaymentOrder(@Body body: RequestBody): ApiEnvelope<CreatePaymentOrderDto>
}
