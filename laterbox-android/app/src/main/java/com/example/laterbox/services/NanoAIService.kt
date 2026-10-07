package com.example.laterbox.services

import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.withTimeout

/** AICore owns the model; no sign-in, subscription, or cloud inference is needed. */
object NanoAIService {
    val status = MutableStateFlow("Checking device support…")
    suspend fun refresh(): Boolean = try {
        val client = Generation.getClient()
        try {
            val feature = withTimeout(10000) { client.checkStatus() }
            status.value = when (feature) {
                FeatureStatus.AVAILABLE -> "Gemini Nano ready"
                FeatureStatus.DOWNLOADABLE -> "Gemini Nano download available"
                FeatureStatus.DOWNLOADING -> "Gemini Nano downloading"
                else -> "Gemini Nano unavailable on this device"
            }
            feature == FeatureStatus.AVAILABLE
        } finally { client.close() }
    } catch (cancelled: kotlinx.coroutines.CancellationException) {
        if (cancelled !is kotlinx.coroutines.TimeoutCancellationException) throw cancelled
        status.value = "Gemini Nano check timed out"; false
    } catch (_: Exception) { status.value = "Gemini Nano unavailable on this device"; false }

    suspend fun download() {
        val client = Generation.getClient()
        try {
            if (client.checkStatus() == FeatureStatus.DOWNLOADABLE) {
                status.value = "Gemini Nano downloading"
                client.download().collect { }
            }
        } finally { client.close() }
        refresh()
    }

    suspend fun generate(prompt: String): String? {
        if (!refresh()) return null
        val client = Generation.getClient()
        return try {
            withTimeout(30000) { client.generateContent(prompt).candidates.firstOrNull()?.text }
        } catch (cancelled: kotlinx.coroutines.CancellationException) {
            if (cancelled !is kotlinx.coroutines.TimeoutCancellationException) throw cancelled
            null
        } catch (_: Exception) {
            status.value = "Gemini Nano temporarily unavailable"; null
        } finally { client.close() }
    }
}
