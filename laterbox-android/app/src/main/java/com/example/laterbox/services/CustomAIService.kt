package com.example.laterbox.services

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

object CustomAIService {
    suspend fun generate(context: Context, prompt: String): String = withContext(Dispatchers.IO) {
        check(AccountService.state.value.pro) { "Custom AI models require verified Pro access." }
        val settings = SecureSettings(context)
        val customKey = settings.apiKey()
        val key = if (customKey.isNotBlank()) customKey else com.example.laterbox.BuildConfig.GEMINI_API_KEY
        require(key.isNotBlank()) { "Gemini API key is not configured." }
        val provider = if (customKey.isNotBlank() && settings.provider != "device") settings.provider else "gemini"
        val model = if (customKey.isNotBlank()) settings.model else com.example.laterbox.BuildConfig.GEMINI_MODEL.ifBlank { "gemini-3.5-flash-lite" }

        val candidateModels = if (provider == "gemini") {
            listOf(model, "gemini-3.5-flash-lite", "gemini-flash-lite-latest", "gemini-3.8-flash").distinct()
        } else {
            listOf(model)
        }

        var lastException: Exception? = null
        for (currentModel in candidateModels) {
            try {
                return@withContext requestModel(provider, currentModel, key, prompt)
            } catch (e: Exception) {
                lastException = e
            }
        }
        throw lastException ?: RuntimeException("Provider request failed.")
    }

    private fun requestModel(provider: String, model: String, key: String, prompt: String): String {
        val endpoint = when(provider) {
            "gemini" -> "https://generativelanguage.googleapis.com/v1beta/models/${URLEncoder.encode(model, "UTF-8")}:generateContent?key=${URLEncoder.encode(key, "UTF-8")}"
            "openai" -> "https://api.openai.com/v1/chat/completions"
            "claude" -> "https://api.anthropic.com/v1/messages"
            else -> error("Select a supported AI provider")
        }
        val body = when(provider) {
            "gemini" -> JSONObject().put("contents", JSONArray().put(JSONObject().put("parts", JSONArray().put(JSONObject().put("text", prompt))))).put("generationConfig", JSONObject().put("responseMimeType", "application/json").put("maxOutputTokens", 2048))
            else -> JSONObject().put("model", model).put(if (provider == "openai") "max_completion_tokens" else "max_tokens", 2048).put("messages", JSONArray().put(JSONObject().put("role", "user").put("content", prompt)))
        }
        val connection = URL(endpoint).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"; connection.connectTimeout = 15000; connection.readTimeout = 45000; connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/json")
            when(provider) {
                "gemini" -> connection.setRequestProperty("x-goog-api-key", key)
                "claude" -> { connection.setRequestProperty("x-api-key", key); connection.setRequestProperty("anthropic-version", "2023-06-01") }
                else -> connection.setRequestProperty("Authorization", "Bearer $key")
            }
            connection.outputStream.use { it.write(body.toString().toByteArray()) }
            if (connection.responseCode !in 200..299) {
                val errorStream = connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
                throw RuntimeException("Provider request failed (${connection.responseCode}): $errorStream")
            }
            val response = JSONObject(connection.inputStream.bufferedReader().use { it.readText() })
            return when(provider) {
                "gemini" -> response.getJSONArray("candidates").getJSONObject(0).getJSONObject("content").getJSONArray("parts").getJSONObject(0).getString("text")
                "claude" -> response.getJSONArray("content").getJSONObject(0).getString("text")
                else -> response.getJSONArray("choices").getJSONObject(0).getJSONObject("message").getString("content")
            }
        } finally { connection.disconnect() }
    }
}
