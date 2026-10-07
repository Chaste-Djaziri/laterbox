package com.example.laterbox.data.api

import com.example.laterbox.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

data class SystemStatusResponse(
    val status: String,
    val label: String,
    val indicator: String,
    val isOperational: Boolean
)

data class EnrichmentResponse(
    val domain: String?,
    val siteName: String?,
    val title: String?,
    val description: String?,
    val faviconUrl: String?,
    val previewImageUrl: String?,
    val contentType: String
)

object LaterBoxApiService {
    var webBaseUrl: String = if (BuildConfig.WEB_BASE_URL.isNotEmpty()) BuildConfig.WEB_BASE_URL else "https://laterbox.dev"
    val supabaseUrl: String = if (BuildConfig.SUPABASE_URL.isNotEmpty()) BuildConfig.SUPABASE_URL else "https://ltjisrgldssqskcylcbj.supabase.co"
    val supabaseAnonKey: String = if (BuildConfig.SUPABASE_KEY.isNotEmpty()) BuildConfig.SUPABASE_KEY else "sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p"

    /**
     * Integrates with Next.js web /api/system-status
     */
    suspend fun fetchSystemStatus(): SystemStatusResponse = withContext(Dispatchers.IO) {
        try {
            val url = URL("$webBaseUrl/api/system-status")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 5000
                readTimeout = 5000
                setRequestProperty("Accept", "application/json")
            }

            if (conn.responseCode in 200..299) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val responseText = reader.readText()
                reader.close()
                val json = JSONObject(responseText)
                val status = json.optString("status", "operational")
                val label = json.optString("label", "All Systems Operational")
                val indicator = json.optString("indicator", "emerald")
                val isOperational = status.equals("operational", ignoreCase = true)
                SystemStatusResponse(status, label, indicator, isOperational)
            } else {
                SystemStatusResponse("Degraded", "Status Unavailable (${conn.responseCode})", "amber", false)
            }
        } catch (e: Exception) {
            SystemStatusResponse("Offline", "Offline / Network Error", "rose", false)
        }
    }

    /**
     * Integrates with Next.js web /api/enrich for rich URL metadata extraction
     */
    suspend fun enrichUrl(targetUrl: String): EnrichmentResponse? = withContext(Dispatchers.IO) {
        try {
            val endpoint = URL("$webBaseUrl/api/enrich")
            val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 8000
                readTimeout = 10000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
            }

            val payload = JSONObject().apply {
                put("url", targetUrl)
            }

            val writer = OutputStreamWriter(conn.outputStream)
            writer.write(payload.toString())
            writer.flush()
            writer.close()

            if (conn.responseCode in 200..299) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val responseText = reader.readText()
                reader.close()
                val json = JSONObject(responseText)

                val domain = json.optString("domain", "").ifEmpty { null }
                val siteName = json.optString("siteName", "").ifEmpty { json.optString("site_name", "").ifEmpty { null } }
                val title = json.optString("title", "").ifEmpty { null }
                val description = json.optString("description", "").ifEmpty { null }
                val faviconUrl = json.optString("faviconUrl", "").ifEmpty { json.optString("favicon_url", "").ifEmpty { null } }
                val previewImageUrl = json.optString("previewImageUrl", "").ifEmpty { json.optString("preview_image_url", "").ifEmpty { null } }

                var contentType = "link"
                val classification = json.optJSONObject("classification")
                if (classification != null) {
                    contentType = classification.optString("contentType", "link")
                }

                EnrichmentResponse(
                    domain = domain,
                    siteName = siteName,
                    title = title,
                    description = description,
                    faviconUrl = faviconUrl,
                    previewImageUrl = previewImageUrl,
                    contentType = contentType
                )
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Captures an item to Supabase Edge function
     */
    suspend fun captureConnectedItem(
        url: String?,
        title: String?,
        text: String?,
        token: String? = null
    ): String? = withContext(Dispatchers.IO) {
        try {
            val endpoint = URL("$supabaseUrl/functions/v1/capture")
            val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 8000
                readTimeout = 10000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("apikey", supabaseAnonKey)
                if (!token.isNullOrEmpty()) {
                    setRequestProperty("Authorization", "Bearer $token")
                }
            }

            val payload = JSONObject().apply {
                put("source", "android_native")
                if (url != null) put("url", url)
                if (title != null) put("title", title)
                if (text != null) put("text", text)
            }

            val writer = OutputStreamWriter(conn.outputStream)
            writer.write(payload.toString())
            writer.flush()
            writer.close()

            if (conn.responseCode in 200..299) {
                val reader = BufferedReader(InputStreamReader(conn.inputStream))
                val responseText = reader.readText()
                reader.close()
                val json = JSONObject(responseText)
                if (json.has("id")) json.getString("id") else null
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
