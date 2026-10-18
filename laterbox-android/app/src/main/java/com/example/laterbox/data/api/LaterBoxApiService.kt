package com.example.laterbox.data.api

import com.example.laterbox.BuildConfig
import com.example.laterbox.SupabaseClient
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

data class ServiceStatusSnapshot(
    val status: String,
    val label: String,
    val monitors: List<ServiceMonitorStatus>,
    val totalMonitors: Int,
    val timestamp: String,
    val statusPageUrl: String = "https://status.laterbox.dev"
)

data class ServiceMonitorStatus(
    val id: String,
    val name: String,
    val status: String,
    val label: String,
    val lastCheckedAt: String?,
    val checkFrequency: Int?
)

data class ServiceUptimeHistory(
    val from: String,
    val to: String,
    val timeZone: String,
    val unit: String,
    val monitors: List<MonitorUptimeHistory>
)

data class MonitorUptimeHistory(
    val id: String,
    val availability: Double?,
    val downtimeSeconds: Double?,
    val buckets: List<UptimeBucket>
)

data class UptimeBucket(
    val id: String,
    val start: String,
    val end: String,
    val availability: Double?,
    val downtimeSeconds: Double
)

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
    val betterstackToken: String = BuildConfig.BETTERSTACK_UPTIME_TOKEN

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

                fun JSONObject.cleanString(key: String): String? {
                    if (isNull(key)) return null
                    val s = optString(key).trim()
                    return if (s.isEmpty() || s.equals("null", ignoreCase = true) || s.equals("undefined", ignoreCase = true)) null else s
                }

                val domain = json.cleanString("domain")
                val siteName = json.cleanString("siteName") ?: json.cleanString("site_name")
                val title = json.cleanString("title")
                val description = json.cleanString("description")
                val faviconUrl = json.cleanString("faviconUrl") ?: json.cleanString("favicon_url")
                val previewImageUrl = json.cleanString("previewImageUrl") ?: json.cleanString("preview_image_url")

                var contentType = "link"
                val classification = json.optJSONObject("classification")
                if (classification != null) {
                    contentType = classification.cleanString("contentType") ?: "link"
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

    /**
     * Fetches detailed Service Status matching iOS ServiceStatusSnapshot.
     * Uses Supabase system-status edge function with direct BetterStack API fallback.
     */
    suspend fun fetchServiceStatusDetails(): ServiceStatusSnapshot = withContext(Dispatchers.IO) {
        // First try the system-status endpoint (uses BETTERSTACK_UPTIME_TOKEN on server)
        try {
            val url = URL("$supabaseUrl/functions/v1/system-status")
            val conn = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 10000
                readTimeout = 15000
                setRequestProperty("apikey", supabaseAnonKey)
                setRequestProperty("Accept", "application/json")
            }

            if (conn.responseCode in 200..299) {
                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                return@withContext parseServiceStatusSnapshot(responseText)
            }
        } catch (_: Exception) {
            // Fall back to direct BetterStack API if available
        }

        // Direct BetterStack API fallback if token is available
        if (betterstackToken.isNotBlank()) {
            try {
                val url = URL("https://uptime.betterstack.com/api/v2/monitors")
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 10000
                    readTimeout = 15000
                    setRequestProperty("Authorization", "Bearer $betterstackToken")
                    setRequestProperty("Accept", "application/json")
                }
                if (conn.responseCode in 200..299) {
                    val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                    return@withContext parseBetterStackDirectMonitors(responseText)
                }
            } catch (_: Exception) {
                // Fall through to error
            }
        }

        throw IllegalStateException("Service status is temporarily unavailable")
    }

    /**
     * Fetches Uptime History matching iOS ServiceUptimeHistory.
     */
    suspend fun fetchUptimeHistory(from: String, to: String, timeZone: String): ServiceUptimeHistory = withContext(Dispatchers.IO) {
        val encodedFrom = java.net.URLEncoder.encode(from, "UTF-8")
        val encodedTo = java.net.URLEncoder.encode(to, "UTF-8")
        val encodedTz = java.net.URLEncoder.encode(timeZone, "UTF-8")
        val url = URL("$supabaseUrl/functions/v1/system-status?history=1&from=$encodedFrom&to=$encodedTo&timeZone=$encodedTz")
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 15000
            readTimeout = 25000
            setRequestProperty("apikey", supabaseAnonKey)
            setRequestProperty("Accept", "application/json")
        }

        if (conn.responseCode in 200..299) {
            val responseText = conn.inputStream.bufferedReader().use { it.readText() }
            return@withContext parseServiceUptimeHistory(responseText)
        } else {
            throw IllegalStateException("Uptime history unavailable: HTTP ${conn.responseCode}")
        }
    }

    fun parseServiceStatusSnapshot(jsonStr: String): ServiceStatusSnapshot {
        val json = JSONObject(jsonStr)
        val status = json.optString("status", "operational")
        val label = json.optString("label", "All systems operational")
        val timestamp = json.optString("timestamp", "")
        val statusPageUrl = json.optString("statusPageUrl", "https://status.laterbox.dev")
        val monitorsArray = json.optJSONArray("monitors") ?: org.json.JSONArray()
        val monitors = mutableListOf<ServiceMonitorStatus>()
        for (i in 0 until monitorsArray.length()) {
            val m = monitorsArray.getJSONObject(i)
            monitors.add(
                ServiceMonitorStatus(
                    id = m.optString("id", i.toString()),
                    name = m.optString("name", "Service Monitor"),
                    status = m.optString("status", "up"),
                    label = m.optString("label", "Operational"),
                    lastCheckedAt = if (m.isNull("lastCheckedAt")) null else m.optString("lastCheckedAt").takeIf { it.isNotBlank() },
                    checkFrequency = if (m.isNull("checkFrequency")) null else m.optInt("checkFrequency").takeIf { it > 0 }
                )
            )
        }
        val totalMonitors = json.optInt("totalMonitors", monitors.size)
        return ServiceStatusSnapshot(status, label, monitors, totalMonitors, timestamp, statusPageUrl)
    }

    fun parseBetterStackDirectMonitors(jsonStr: String): ServiceStatusSnapshot {
        val json = JSONObject(jsonStr)
        val dataArray = json.optJSONArray("data") ?: org.json.JSONArray()
        val monitors = mutableListOf<ServiceMonitorStatus>()
        for (i in 0 until dataArray.length()) {
            val item = dataArray.getJSONObject(i)
            val id = item.optString("id", i.toString())
            val attrs = item.optJSONObject("attributes") ?: JSONObject()
            val isPaused = attrs.optBoolean("paused", false)
            val rawStatus = attrs.optString("status", "up")
            val status = if (isPaused) "paused" else rawStatus
            val name = attrs.optString("pronounceable_name").takeIf { it.isNotBlank() } ?: "Monitor ${i + 1}"
            val label = when (status) {
                "up" -> "Operational"
                "down" -> "Service disruption"
                "degraded" -> "Degraded performance"
                "validating" -> "Recovering"
                "maintenance" -> "Maintenance"
                "paused" -> "Paused"
                else -> "Operational"
            }
            val lastCheckedAt = if (attrs.isNull("last_checked_at")) null else attrs.optString("last_checked_at")
            val checkFrequency = if (attrs.isNull("check_frequency")) null else attrs.optInt("check_frequency")
            monitors.add(ServiceMonitorStatus(id, name, status, label, lastCheckedAt, checkFrequency))
        }
        val active = monitors.filter { it.status != "paused" }
        val overallStatus = when {
            active.any { it.status == "down" } -> "outage"
            active.any { it.status == "degraded" || it.status == "validating" } -> "degraded"
            active.any { it.status == "maintenance" } -> "maintenance"
            active.isNotEmpty() && active.all { it.status == "up" } -> "operational"
            else -> "operational"
        }
        val overallLabel = when (overallStatus) {
            "outage" -> "Some services are unavailable"
            "degraded" -> "Some services are recovering"
            "maintenance" -> "Scheduled maintenance"
            else -> "All systems operational"
        }
        return ServiceStatusSnapshot(overallStatus, overallLabel, monitors, monitors.size, java.time.Instant.now().toString(), "https://status.laterbox.dev")
    }

    fun parseServiceUptimeHistory(jsonStr: String): ServiceUptimeHistory {
        val json = JSONObject(jsonStr)
        val from = json.optString("from", "")
        val to = json.optString("to", "")
        val timeZone = json.optString("timeZone", "UTC")
        val unit = json.optString("unit", "day")
        val monitorsArray = json.optJSONArray("monitors") ?: org.json.JSONArray()
        val monitors = mutableListOf<MonitorUptimeHistory>()
        for (i in 0 until monitorsArray.length()) {
            val m = monitorsArray.getJSONObject(i)
            val id = m.optString("id", "")
            val availability = if (m.isNull("availability")) null else m.optDouble("availability")
            val downtimeSeconds = if (m.isNull("downtimeSeconds")) null else m.optDouble("downtimeSeconds")
            val bucketsArray = m.optJSONArray("buckets") ?: org.json.JSONArray()
            val buckets = mutableListOf<UptimeBucket>()
            for (j in 0 until bucketsArray.length()) {
                val b = bucketsArray.getJSONObject(j)
                val start = b.optString("start", "")
                val end = b.optString("end", "")
                val bAvail = if (b.isNull("availability")) null else b.optDouble("availability")
                val bDown = b.optDouble("downtimeSeconds", 0.0)
                buckets.add(UptimeBucket(id = start, start = start, end = end, availability = bAvail, downtimeSeconds = bDown))
            }
            monitors.add(MonitorUptimeHistory(id, availability, downtimeSeconds, buckets))
        }
        return ServiceUptimeHistory(from, to, timeZone, unit, monitors)
    }

    val billingUrl: String = "https://app.laterbox.dev"

    /**
     * Obtains the direct Paddle Customer Portal URL for managing subscription.
     * Calls POST /api/billing/portal with action="manage" and user bearer token.
     */
    suspend fun getPaddleManagementUrl(authToken: String? = null): String? = withContext(Dispatchers.IO) {
        val token = authToken ?: runCatching {
            SupabaseClient.client.auth.currentSessionOrNull()?.accessToken
        }.getOrNull()
        if (token.isNullOrBlank()) return@withContext null

        try {
            val endpoint = URL("$billingUrl/api/billing/portal")
            val conn = (endpoint.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10000
                readTimeout = 15000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("Authorization", "Bearer $token")
            }

            val payload = JSONObject().apply {
                put("action", "manage")
            }

            OutputStreamWriter(conn.outputStream).use { writer ->
                writer.write(payload.toString())
                writer.flush()
            }

            if (conn.responseCode in 200..299) {
                val responseText = conn.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(responseText)
                json.optString("url", "").takeIf { it.startsWith("https://") }
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
