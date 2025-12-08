package com.buka.novelapp

import android.app.Application
import com.buka.novelapp.data.network.ApiClient
import com.buka.novelapp.data.repository.NovelRepository
import com.buka.novelapp.data.storage.AuthStorage

class NovelApp : Application() {
    lateinit var repository: NovelRepository
        private set

    override fun onCreate() {
        super.onCreate()
        val authStorage = AuthStorage(applicationContext)
        val apiClient = ApiClient(authStorage)
        repository = NovelRepository(apiClient, authStorage)
    }
}
