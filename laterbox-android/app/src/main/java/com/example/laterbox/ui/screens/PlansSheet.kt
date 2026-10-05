package com.example.laterbox.ui.screens

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.android.billingclient.api.ProductDetails
import com.example.laterbox.services.*
import com.example.laterbox.ui.capture.Choice
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlansSheet(onDismiss: () -> Unit) {
    val activity = LocalContext.current as Activity; val scope = rememberCoroutineScope()
    var products by remember { mutableStateOf<List<ProductDetails>>(emptyList()) }; var error by remember { mutableStateOf<String?>(null) }; var busy by remember { mutableStateOf(true) }
    val account by AccountService.state.collectAsState()
    val billing = remember { BillingService(activity) { purchases -> scope.launch { busy = true; try { purchases.forEach { billingPurchase -> BillingService(activity) {}.use { it.verify(billingPurchase) } }; error = "Purchase verified. Pro access refreshed." } catch (failure: Exception) { error = failure.message } finally { busy = false } } } }
    DisposableEffect(billing) { onDispose { billing.close() } }
    LaunchedEffect(billing) { try { billing.connect(); products = billing.products(); if (products.isEmpty()) error = "Plans are unavailable in this installation. Install the Play testing release to purchase." } catch (failure: Exception) { error = failure.message } finally { busy = false } }
    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.fillMaxWidth().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("LaterBox Pro", style = MaterialTheme.typography.headlineLarge)
            Text("Cloud sync and AI Inbox Organizer. Local capture, local search, and on-device Later AI are free.")
            if (account.userId == null) Text("Sign in before purchasing or restoring Pro.")
            products.forEach { product ->
                val phases = product.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList.orEmpty()
                Choice(product.name, phases.joinToString(" → ") { "${it.formattedPrice} / ${it.billingPeriod}" }) { runCatching { check(account.userId != null); val result = billing.purchase(product); check(result.responseCode == 0) { "Purchase could not start (${result.responseCode})" } }.onFailure { error = it.message } }
            }
            if (busy) CircularProgressIndicator()
            error?.let { Text(it) }
            Button(onClick = { scope.launch { busy = true; try { check(account.userId != null) { "Sign in first" }; val purchases = billing.restore(); purchases.forEach { billing.verify(it) }; AccountService.refresh(); error = if (account.pro || AccountService.state.value.pro) "Pro restored" else "No active Pro purchase found for this account." } catch (failure: Exception) { error = failure.message } finally { busy = false } } }, enabled = !busy) { Text("Restore purchases") }
            TextButton(onClick = { activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/account/subscriptions?package=pro.micorp.laterbox"))) }) { Text("Manage Play subscriptions") }
            TextButton(onClick = onDismiss) { Text("Close") }
        }
    }
}
