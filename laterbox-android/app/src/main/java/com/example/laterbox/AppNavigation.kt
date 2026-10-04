package com.example.laterbox

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation3.NavDisplay
import androidx.navigation3.rememberNavWrapperManager
import androidx.navigation3.NavBackStackProvider

@Composable
fun AppNavigation() {
    val navWrapperManager = rememberNavWrapperManager(emptyList())
    NavBackStackProvider("Home") { backStack ->
        NavDisplay(
            backstack = backStack,
            wrapperManager = navWrapperManager
        ) { route ->
            when (route) {
                "Home" -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(text = "Welcome to Laterbox")
                }
                else -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(text = "Not Found")
                }
            }
        }
    }
}
