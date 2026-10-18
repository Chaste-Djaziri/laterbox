package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.laterbox.services.AccountService
import com.example.laterbox.theme.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlansSheet(onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val account by AccountService.state.collectAsState()
    var selectedPlan by remember { mutableStateOf("Annual") }
    var message by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = LaterboxBg) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.padding(top = 4.dp).size(68.dp).background(LaterboxAccent, CircleShape), contentAlignment = Alignment.Center) { Icon(Icons.Default.Star, null, tint = LaterboxTextPrimary, modifier = Modifier.size(34.dp)) }
            Text("LaterBox Pro", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, modifier = Modifier.padding(top = 12.dp))
            Text("Pro app icons and your choice of AI providers on this device. Connect an optional account for cloud sync, backup, and web access.", color = LaterboxTextSecondary, textAlign = TextAlign.Center, fontSize = 14.sp, modifier = Modifier.padding(top = 6.dp, bottom = 20.dp))
            if (account.pro) {
                PlanCard(true, Modifier.fillMaxWidth()) {
                    Icon(Icons.Default.CheckCircle, null, tint = Color(0xFF16A34A), modifier = Modifier.size(24.dp))
                    Column(Modifier.weight(1f).padding(start = 10.dp)) { Text("LaterBox Pro Active", fontWeight = FontWeight.Bold, color = LaterboxTextPrimary); Text("Cloud sync is enabled on this account", fontSize = 12.sp, color = LaterboxTextSecondary) }
                    Text("Active", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary, modifier = Modifier.background(LaterboxAccent, RoundedCornerShape(20.dp)).padding(horizontal = 10.dp, vertical = 5.dp))
                }
                Spacer(Modifier.height(12.dp))
            }
            PlanOption("Annual", "$3.99", "/ year", "Best value for full access", selectedPlan == "Annual") { selectedPlan = "Annual" }
            Spacer(Modifier.height(12.dp))
            PlanOption("Monthly", "$4.99", "/ month", "Flexible month-to-month access", selectedPlan == "Monthly") { selectedPlan = "Monthly" }
            Spacer(Modifier.height(14.dp))
            Button(onClick = {
                if (account.pro) scope.launch { busy = true; try { val url = com.example.laterbox.data.api.LaterBoxApiService.getPaddleManagementUrl(); context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url ?: "https://app.laterbox.dev/login?next=%2Fplans"))) } catch (_: Exception) { message = "Could not open subscription management. Please try again." }; busy = false }
                else runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://app.laterbox.dev/login?next=%2Fplans"))) }.onFailure { message = "Could not open your browser. Visit app.laterbox.dev/plans to subscribe." }
            }, enabled = !busy, modifier = Modifier.fillMaxWidth().height(54.dp), shape = RoundedCornerShape(14.dp), colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1A1A1A), contentColor = Color.White)) {
                if (busy) CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp)) else { Icon(Icons.Default.Star, null, modifier = Modifier.size(18.dp)); Spacer(Modifier.width(8.dp)); Text(if (account.pro) "Manage Subscription" else "Get Pro on web", fontWeight = FontWeight.Bold) }
            }
            if (!account.pro) Text("Subscribe on LaterBox Web to enable cloud sync on Android.", color = LaterboxTextSecondary, fontSize = 12.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 8.dp))
            Spacer(Modifier.height(22.dp)); FeatureBreakdown()
            if (account.pro) OutlinedButton(onClick = { scope.launch { busy = true; try { AccountService.refresh(); message = "Subscription status refreshed." } catch (_: Exception) { message = "Could not refresh your subscription. Please try again." }; busy = false } }, enabled = !busy, modifier = Modifier.fillMaxWidth().padding(top = 14.dp)) { Icon(Icons.Default.Refresh, null, modifier = Modifier.size(17.dp)); Spacer(Modifier.width(6.dp)); Text("Refresh subscription") }
            message?.let { Text(it, color = LaterboxTextSecondary, fontSize = 12.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 10.dp)) }
            TextButton(onClick = onDismiss, modifier = Modifier.padding(bottom = 12.dp)) { Text("Close", color = LaterboxTextSecondary) }
        }
    }
}

@Composable private fun PlanOption(title: String, price: String, period: String, detail: String, selected: Boolean, onClick: () -> Unit) {
    PlanCard(selected, Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Box(Modifier.size(22.dp).background(if (selected) LaterboxTextPrimary else Color.Transparent, CircleShape), contentAlignment = Alignment.Center) { Surface(shape = CircleShape, color = if (selected) LaterboxTextPrimary else Color.Transparent, border = BorderStroke(2.dp, if (selected) LaterboxTextPrimary else LaterboxTextSecondary.copy(alpha = .35f)), modifier = Modifier.fillMaxSize()) {} }
        Column(Modifier.weight(1f).padding(start = 12.dp)) { Text(title, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary); Text(detail, fontSize = 12.sp, color = LaterboxTextSecondary) }
        Row(verticalAlignment = Alignment.Bottom) { Text(price, fontWeight = FontWeight.Bold, color = LaterboxTextPrimary); Text(period, fontSize = 12.sp, color = LaterboxTextSecondary) }
    }
}

@Composable private fun PlanCard(selected: Boolean, modifier: Modifier = Modifier, content: @Composable RowScope.() -> Unit) {
    Surface(modifier = modifier, shape = RoundedCornerShape(16.dp), color = LaterboxCard, border = BorderStroke(if (selected) 2.dp else 1.dp, if (selected) LaterboxTextPrimary else LaterboxBorder)) { Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically, content = content) }
}

@Composable private fun FeatureBreakdown() {
    Column(Modifier.fillMaxWidth()) {
        Text("WHAT'S INCLUDED WITH PRO", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = LaterboxTextSecondary, modifier = Modifier.padding(bottom = 10.dp))
        Surface(shape = RoundedCornerShape(18.dp), color = LaterboxCard, border = BorderStroke(1.dp, LaterboxBorder)) { Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) { FeatureRow(Icons.Default.Cloud, "Multi-Device Cloud Sync", "Optional account connection enables sync across devices."); FeatureRow(Icons.Default.SmartToy, "AI Inbox Organizer", "Use compatible on-device AI or your own provider keys."); FeatureRow(Icons.Default.Devices, "Browser & Desktop Extensions", "Browser extensions and local capture remain free."); FeatureRow(Icons.Default.Lock, "Encrypted Cloud Backup", "Optional account connection enables backup and restore.") } }
    }
}

@Composable private fun FeatureRow(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String) {
    Row(verticalAlignment = Alignment.Top) { Box(Modifier.size(32.dp).background(LaterboxAccent.copy(alpha = .65f), CircleShape), contentAlignment = Alignment.Center) { Icon(icon, null, tint = LaterboxTextPrimary, modifier = Modifier.size(17.dp)) }; Column(Modifier.padding(start = 12.dp)) { Text(title, fontWeight = FontWeight.SemiBold, color = LaterboxTextPrimary); Text(subtitle, fontSize = 12.sp, color = LaterboxTextSecondary) } }
}
