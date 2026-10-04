package com.example.laterbox

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.laterbox.theme.LaterboxTheme
import io.github.jan.supabase.auth.handleDeeplinks

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle deep link for Supabase authentication
        SupabaseClient.client.handleDeeplinks(intent)

        enableEdgeToEdge()
        setContent {
            LaterboxTheme { 
                Surface(
                    modifier = Modifier.fillMaxSize()
                ) {
                    AppNavigation() 
                } 
            }
        }
    }
}
