package com.example.laterbox.ui.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.R
import com.example.laterbox.SupabaseClient
import com.example.laterbox.theme.LaterboxAccent
import com.example.laterbox.theme.LaterboxAmber
import com.example.laterbox.theme.LaterboxBg
import com.example.laterbox.theme.LaterboxBorder
import com.example.laterbox.theme.LaterboxCard
import com.example.laterbox.theme.LaterboxDarkSurface
import com.example.laterbox.theme.LaterboxEmerald
import com.example.laterbox.theme.LaterboxIndigo
import com.example.laterbox.theme.LaterboxTextPrimary
import com.example.laterbox.theme.LaterboxTextSecondary
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.OTP
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun WelcomeScreen(
    onContinueAsGuest: () -> Unit,
    onOpenSignIn: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(LaterboxBg)
            .padding(horizontal = 24.dp, vertical = 24.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        // Top Bar: Official Logo & Sign In Button
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Image(
                painter = painterResource(id = R.drawable.laterbox_logo),
                contentDescription = "Laterbox",
                modifier = Modifier.height(34.dp),
                contentScale = ContentScale.Fit
            )

            Surface(
                shape = RoundedCornerShape(20.dp),
                color = LaterboxCard,
                border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder)
            ) {
                Text(
                    text = "Sign In",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = LaterboxTextPrimary,
                    modifier = Modifier
                        .clickable { onOpenSignIn() }
                        .padding(horizontal = 16.dp, vertical = 7.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Center Hero Section with Official Illustration
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Image(
                painter = painterResource(id = R.drawable.onboarding_hero),
                contentDescription = "Laterbox Onboarding",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(280.dp)
                    .clip(RoundedCornerShape(24.dp)),
                contentScale = ContentScale.Fit
            )

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "The calm place for everything you want later",
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Black,
                    textAlign = TextAlign.Center,
                    lineHeight = 32.sp,
                    color = LaterboxTextPrimary
                )
                Text(
                    text = "Save links, videos, and articles in one tap. Schedule deliberate returns when you're truly ready to read.",
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center,
                    lineHeight = 20.sp,
                    color = LaterboxTextSecondary
                )
            }

            // Value props
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                FeatureRow(
                    icon = Icons.Default.Schedule,
                    iconColor = LaterboxAmber,
                    title = "Scheduled Returns",
                    subtitle = "Never lose content in bottomless bookmark lists"
                )
                FeatureRow(
                    icon = Icons.Default.AutoAwesome,
                    iconColor = LaterboxIndigo,
                    title = "Later AI Intelligence",
                    subtitle = "Ask questions and organize your saved vault effortlessly"
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Bottom CTA Buttons
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Button(
                onClick = onContinueAsGuest,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = LaterboxDarkSurface,
                    contentColor = Color.White
                )
            ) {
                Text(
                    text = "Get Started",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            OutlinedButton(
                onClick = onOpenSignIn,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(16.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, LaterboxBorder),
                colors = ButtonDefaults.outlinedButtonColors(
                    containerColor = LaterboxCard,
                    contentColor = LaterboxTextPrimary
                )
            ) {
                Text(
                    text = "Sign In with Email",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun FeatureRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(LaterboxCard)
            .padding(14.dp)
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(iconColor.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor,
                modifier = Modifier.size(18.dp)
            )
        }

        Column {
            Text(
                text = title,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = LaterboxTextPrimary
            )
            Text(
                text = subtitle,
                fontSize = 12.sp,
                color = LaterboxTextSecondary
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthSheet(
    onDismiss: () -> Unit,
    onAuthenticated: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var email by remember { mutableStateOf("") }
    var otpCode by remember { mutableStateOf("") }
    var codeSent by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var statusMessage by remember { mutableStateOf<String?>(null) }
    var isError by remember { mutableStateOf(false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = LaterboxBg,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 8.dp)
                .padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // Header with Close
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Image(
                    painter = painterResource(id = R.drawable.laterbox_logo),
                    contentDescription = "Laterbox",
                    modifier = Modifier.height(28.dp),
                    contentScale = ContentScale.Fit
                )

                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close", tint = LaterboxTextSecondary)
                }
            }

            // Auth Hero Artwork
            Image(
                painter = painterResource(id = R.drawable.auth_hero),
                contentDescription = "Sign In Illustration",
                modifier = Modifier
                    .size(130.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = if (codeSent) "Verify Email Code" else "Sign in to Laterbox",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = LaterboxTextPrimary
                )
                Text(
                    text = if (codeSent)
                        "Enter the 6-digit verification code sent to $email."
                    else
                        "Enter your email to receive a passwordless sign-in code.",
                    fontSize = 13.sp,
                    color = LaterboxTextSecondary,
                    textAlign = TextAlign.Center
                )
            }

            if (!codeSent) {
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    placeholder = { Text("you@example.com") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true,
                    leadingIcon = { Icon(Icons.Default.Email, null, tint = LaterboxTextSecondary) },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = LaterboxDarkSurface,
                        unfocusedBorderColor = LaterboxBorder,
                        focusedContainerColor = LaterboxCard,
                        unfocusedContainerColor = LaterboxCard
                    )
                )
            } else {
                OutlinedTextField(
                    value = otpCode,
                    onValueChange = { otpCode = it },
                    placeholder = { Text("123456") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = LaterboxDarkSurface,
                        unfocusedBorderColor = LaterboxBorder,
                        focusedContainerColor = LaterboxCard,
                        unfocusedContainerColor = LaterboxCard
                    )
                )
            }

            if (statusMessage != null) {
                Text(
                    text = statusMessage ?: "",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = if (isError) Color.Red else LaterboxEmerald
                )
            }

            Button(
                onClick = {
                    if (!codeSent) {
                        if (email.isNotBlank()) {
                            isLoading = true
                            scope.launch {
                                try {
                                    SupabaseClient.client.auth.signInWith(OTP) {
                                        this.email = email.trim()
                                    }
                                    codeSent = true
                                    statusMessage = "Verification code sent to $email"
                                    isError = false
                                } catch (e: Exception) {
                                    statusMessage = "Unable to send the code. Check your connection and retry."
                                    isError = true
                                } finally {
                                    isLoading = false
                                }
                            }
                        }
                    } else {
                        if (otpCode.isNotBlank()) {
                            isLoading = true
                            scope.launch {
                                try {
                                    SupabaseClient.client.auth.verifyEmailOtp(
                                        type = io.github.jan.supabase.auth.OtpType.Email.EMAIL,
                                        email = email.trim(), token = otpCode.trim()
                                    )
                                    com.example.laterbox.services.AccountService.refresh()
                                    onAuthenticated()
                                    onDismiss()
                                } catch (e: Exception) {
                                    statusMessage = "Verification failed. Check the code and try again."
                                    isError = true
                                } finally { isLoading = false }
                            }
                        }
                    }
                },
                enabled = !isLoading && (if (!codeSent) email.isNotBlank() else otpCode.isNotBlank()),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = LaterboxDarkSurface,
                    contentColor = Color.White
                )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = Color.White
                    )
                } else {
                    Text(
                        text = if (!codeSent) "Send Code" else "Verify & Sign In",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
