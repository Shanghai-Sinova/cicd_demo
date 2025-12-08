package com.buka.novelapp.data.network

import com.buka.novelapp.BuildConfig
import com.buka.novelapp.data.storage.AuthStorage
import java.util.concurrent.TimeUnit
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory

class ApiClient(private val authStorage: AuthStorage) {
    @Volatile
    var accessToken: String? = null
        private set

    suspend fun hydrateToken() {
        accessToken = authStorage.getToken()
    }

    fun setToken(token: String?) {
        accessToken = token
    }

    @OptIn(ExperimentalSerializationApi::class)
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        explicitNulls = false
        isLenient = true
    }

    private val authInterceptor = Interceptor { chain ->
        val builder = chain.request().newBuilder()
        builder.addHeader("Accept", "application/json")
        if (chain.request().header("Content-Type") == null) {
            builder.addHeader("Content-Type", "application/json")
        }
        accessToken?.let {
            builder.addHeader("Authorization", "Bearer $it")
        }
        chain.proceed(builder.build())
    }

    private val logging = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttp: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(BuildConfig.API_TIMEOUT_SECONDS.toLong(), TimeUnit.SECONDS)
        .readTimeout(BuildConfig.API_TIMEOUT_SECONDS.toLong(), TimeUnit.SECONDS)
        .writeTimeout(BuildConfig.API_TIMEOUT_SECONDS.toLong(), TimeUnit.SECONDS)
        .addInterceptor(authInterceptor)
        .addInterceptor(logging)
        .build()

    private val retrofit: Retrofit = Retrofit.Builder()
        .baseUrl("https://stage-api.bukabuka.com.cn/api/v1/")
        .client(okHttp)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()

    val api: NovelApi = retrofit.create(NovelApi::class.java)
}
