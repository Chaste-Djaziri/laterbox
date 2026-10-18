package com.example.laterbox.services

import android.app.Activity
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import com.example.laterbox.SupabaseClient
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.auth

object GoogleAuthService {
    const val webClientId = "746759149159-l2gio633l3n86vd40kt0a9ncj03m8hcl.apps.googleusercontent.com"

    suspend fun signIn(activity: Activity) {
        val credentialManager = CredentialManager.create(activity)
        val option = GetGoogleIdOption.Builder()
            .setServerClientId(webClientId)
            .setFilterByAuthorizedAccounts(false)
            .setAutoSelectEnabled(false)
            .build()
        val result = credentialManager.getCredential(
            activity,
            GetCredentialRequest.Builder().addCredentialOption(option).build()
        )
        val credential = try {
            GoogleIdTokenCredential.createFrom(result.credential.data)
        } catch (error: GoogleIdTokenParsingException) {
            throw IllegalStateException("Google returned an invalid sign-in token.", error)
        }
        val token = credential.idToken.trim()
        check(token.isNotEmpty()) { "Google did not return an ID token." }
        SupabaseClient.client.auth.signInWith(IDToken) {
            idToken = token
            provider = Google
        }
        AccountService.refresh()
    }

    suspend fun link(activity: Activity) {
        // Google identity linking is completed by the same ID-token exchange while
        // the existing Supabase session is active; Supabase preserves the user ID.
        signIn(activity)
    }
}
