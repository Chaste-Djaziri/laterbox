package com.example.laterbox.services

import android.content.Context
import org.json.JSONObject

object RemoteAIService {
    // An intentional rollout switch, independent from the server's disabled-by-default flag.
    const val ENABLED = false
    fun available(context: Context): Boolean = ENABLED && AccountService.state.value.pro &&
        context.getSharedPreferences("laterbox", 0).getBoolean("gemini_fallback", false)
    suspend fun generate(context: Context, prompt: String): String {
        check(available(context)) { "Remote Gemini is disabled. Your content is still available locally." }
        val response = NativeApi.call("https://laterbox.dev/api/ai/android", "POST", JSONObject().put("prompt", prompt))
        return JSONObject(response).getJSONObject("action").toString()
    }
}
