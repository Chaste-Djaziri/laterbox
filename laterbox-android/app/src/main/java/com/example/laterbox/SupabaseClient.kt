package com.example.laterbox

import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.postgrest.Postgrest

object SupabaseClient {
    val client = createSupabaseClient(
        supabaseUrl = com.example.laterbox.data.api.LaterBoxApiService.supabaseUrl,
        supabaseKey = com.example.laterbox.data.api.LaterBoxApiService.supabaseAnonKey
    ) {
        install(Auth) {
            scheme = "laterbox"
            host = "login-callback"
        }
        install(Postgrest)
    }
}
