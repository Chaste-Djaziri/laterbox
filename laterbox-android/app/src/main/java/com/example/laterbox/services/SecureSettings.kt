package com.example.laterbox.services

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecureSettings(context: Context) {
    private val preferences = context.getSharedPreferences("laterbox_ai", 0)
    var provider: String
        get() = preferences.getString("provider", "gemini")?.takeIf { it != "device" } ?: "gemini"
        set(value) { preferences.edit().putString("provider", value).apply() }
    var model: String
        get() = preferences.getString("model", "gemini-3.5-flash-lite")?.takeIf { it != "gemini-1.5-flash" && it != "gemini-2.5-flash" } ?: "gemini-3.5-flash-lite"
        set(value) { preferences.edit().putString("model", value).apply() }
    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        return store.getKey("laterbox-ai", null) as? SecretKey ?: KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder("laterbox-ai", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
    fun apiKey(): String = runCatching {
        val stored = preferences.getString("api_key", null) ?: return ""
        val parts = stored.split(':'); val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)))
        cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)).toString(Charsets.UTF_8)
    }.getOrDefault("")
    fun setApiKey(value: String) {
        if (value.isBlank()) { preferences.edit().remove("api_key").apply(); return }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key()) }
        preferences.edit().putString("api_key", Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + ":" + Base64.encodeToString(cipher.doFinal(value.toByteArray()), Base64.NO_WRAP)).apply()
    }
}
