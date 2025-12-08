package com.buka.novelapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.lifecycle.viewmodel.compose.viewModel
import com.buka.novelapp.ui.navigation.NovelNavHost
import com.buka.novelapp.ui.theme.NovelTheme
import com.buka.novelapp.ui.viewmodel.ViewModelFactory

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val repository = (application as NovelApp).repository
        setContent {
            NovelTheme {
                Surface(color = MaterialTheme.colorScheme.background) {
                    val factory = remember { ViewModelFactory(repository) }
                    NovelNavHost(factory = factory)
                }
            }
        }
    }
}
