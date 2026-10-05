package com.example.laterbox.services

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

object AppLockService {
    private const val METHODS = BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL
    fun supported(context: Context) = BiometricManager.from(context).canAuthenticate(METHODS) == BiometricManager.BIOMETRIC_SUCCESS
    fun authenticate(activity: FragmentActivity, onSuccess: () -> Unit, onError: (String) -> Unit) {
        val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) { onSuccess() }
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) { onError(errString.toString()) }
        })
        prompt.authenticate(BiometricPrompt.PromptInfo.Builder().setTitle("Unlock LaterBox").setSubtitle("Access your private vault").setAllowedAuthenticators(METHODS).build())
    }
}
