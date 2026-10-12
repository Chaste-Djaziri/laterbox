package com.example.laterbox.services

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.*
import com.example.laterbox.MainActivity
import com.example.laterbox.R
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

object ReturnsService {
    const val CHANNEL_ID = "returns"
    private val recentlyNotified = ConcurrentHashMap<String, Long>()

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Saved item returns",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Reminders for saved items scheduled to return to your Inbox"
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    fun sendReturnNotification(context: Context, item: ItemEntity) {
        val nowMs = System.currentTimeMillis()
        val lastTime = recentlyNotified[item.id]
        if (lastTime != null && (nowMs - lastTime) < 60_000L) {
            return
        }
        recentlyNotified[item.id] = nowMs

        ensureChannel(context)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("item_id", item.id)
        }
        val pending = PendingIntent.getActivity(
            context,
            item.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val rawTitle = item.title?.trim()
        val title = if (!rawTitle.isNullOrBlank()) rawTitle else "Time to return to this"
        val rawDesc = item.summary.trim().takeIf { it.isNotBlank() }
            ?: item.textContent?.trim()?.take(160)?.takeIf { it.isNotBlank() }
            ?: item.url?.trim()?.takeIf { it.isNotBlank() }
            ?: "Your scheduled item is back in your Inbox."

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.laterbox_accent))
            .setContentTitle(title)
            .setContentText(rawDesc)
            .setStyle(NotificationCompat.BigTextStyle().bigText(rawDesc).setBigContentTitle(title))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(pending)
            .setAutoCancel(true)
            .build()

        manager.notify(item.id.hashCode(), notification)
    }

    fun schedule(context: Context, item: ItemEntity) {
        val date = item.returnAt?.let { runCatching { Instant.parse(it) }.getOrNull() }
        if (date == null || item.deletedAt != null || item.status != "deferred") {
            cancel(context, item.id)
            return
        }

        val delayMs = date.toEpochMilli() - System.currentTimeMillis()
        if (delayMs <= 0) {
            CoroutineScope(Dispatchers.IO).launch {
                val dao = AppDatabase.getDatabase(context).itemDao()
                val now = Instant.now().toString()
                dao.promoteItem(item.id, now)
                sendReturnNotification(context, item.copy(status = "inbox"))
            }
            cancel(context, item.id)
            return
        }

        // 1. Schedule exact or wake-up alarm with AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val alarmIntent = Intent(context, ReturnReceiver::class.java).apply {
            putExtra("id", item.id)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            item.id.hashCode(),
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (alarmManager != null) {
            val triggerAt = date.toEpochMilli()
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                        } else {
                            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                        }
                    } else {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                    }
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
            } catch (e: SecurityException) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } catch (e: Exception) {
                // Ignore unexpected alarm errors
            }
        }

        // 2. Backup scheduling with WorkManager
        val work = OneTimeWorkRequestBuilder<ReturnWorker>()
            .setInputData(workDataOf("id" to item.id))
            .setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork("return-${item.id}", ExistingWorkPolicy.REPLACE, work)
    }

    fun cancel(context: Context, itemId: String) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            val alarmIntent = Intent(context, ReturnReceiver::class.java).apply {
                putExtra("id", itemId)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                itemId.hashCode(),
                alarmIntent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager?.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        } catch (e: Exception) {
            // Ignore cancel errors
        }
        try {
            WorkManager.getInstance(context).cancelUniqueWork("return-$itemId")
        } catch (e: Exception) {
            // Ignore cancel errors
        }
    }
}

class ReturnReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val itemId = intent.getStringExtra("id") ?: return
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val dao = AppDatabase.getDatabase(context).itemDao()
                val item = dao.getItemById(itemId)
                if (item != null && item.deletedAt == null && item.status == "deferred") {
                    val now = Instant.now().toString()
                    dao.promoteItem(item.id, now)
                    ReturnsService.sendReturnNotification(context, item.copy(status = "inbox"))
                }
            } catch (e: Exception) {
                // Ignore errors
            } finally {
                pendingResult.finish()
            }
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == "android.intent.action.QUICKBOOT_POWERON") {
            val pendingResult = goAsync()
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val dao = AppDatabase.getDatabase(context).itemDao()
                    val now = Instant.now().toString()
                    val due = dao.getDueItems(now)
                    if (due.isNotEmpty()) {
                        dao.promoteDue(now)
                        due.forEach { ReturnsService.sendReturnNotification(context, it.copy(status = "inbox")) }
                    }
                    val all = dao.getAllItems()
                    all.filter { it.status == "deferred" && it.deletedAt == null }.forEach {
                        ReturnsService.schedule(context, it)
                    }
                } catch (e: Exception) {
                    // Ignore errors
                } finally {
                    pendingResult.finish()
                }
            }
        }
    }
}

class ReturnWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val dao = AppDatabase.getDatabase(applicationContext).itemDao()
        val item = inputData.getString("id")?.let { dao.getItemById(it) } ?: return Result.success()
        if (item.deletedAt != null || item.status != "deferred") return Result.success()
        val date = item.returnAt?.let { runCatching { Instant.parse(it) }.getOrNull() } ?: return Result.success()
        if (date.isAfter(Instant.now())) {
            ReturnsService.schedule(applicationContext, item)
            return Result.success()
        }
        val now = Instant.now().toString()
        dao.promoteItem(item.id, now)
        ReturnsService.sendReturnNotification(applicationContext, item.copy(status = "inbox"))
        return Result.success()
    }
}
