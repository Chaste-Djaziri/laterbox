package com.example.laterbox.services

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.*
import com.example.laterbox.MainActivity
import com.example.laterbox.R
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import java.time.Instant
import java.util.concurrent.TimeUnit

object ReturnsService {
    const val CHANNEL_ID = "returns"
    fun ensureChannel(context: Context) {
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Saved item returns", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Reminders for saved items scheduled to return to your Inbox"
            }
        )
    }

    fun schedule(context: Context, item: ItemEntity) {
        val manager = WorkManager.getInstance(context)
        val date = item.returnAt?.let { runCatching { Instant.parse(it) }.getOrNull() }
        if (date == null || item.deletedAt != null || item.status != "deferred") { manager.cancelUniqueWork("return-${item.id}"); return }
        val work = OneTimeWorkRequestBuilder<ReturnWorker>().setInputData(workDataOf("id" to item.id))
            .setInitialDelay((date.toEpochMilli() - System.currentTimeMillis()).coerceAtLeast(0), TimeUnit.MILLISECONDS).build()
        manager.enqueueUniqueWork("return-${item.id}", ExistingWorkPolicy.REPLACE, work)
    }
}
class ReturnWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        val dao = AppDatabase.getDatabase(applicationContext).itemDao()
        val item = inputData.getString("id")?.let { dao.getItemById(it) } ?: return Result.success()
        if (item.deletedAt != null || item.status != "deferred") return Result.success()
        val date = item.returnAt?.let { Instant.parse(it) } ?: return Result.success()
        if (date.isAfter(Instant.now())) { ReturnsService.schedule(applicationContext, item); return Result.success() }
        dao.updateStatus(item.id, "inbox", Instant.now().toString())
        val manager = applicationContext.getSystemService(NotificationManager::class.java)
        ReturnsService.ensureChannel(applicationContext)
        if (ContextCompat.checkSelfPermission(applicationContext, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED || android.os.Build.VERSION.SDK_INT < 33) {
            val intent = Intent(applicationContext, MainActivity::class.java).putExtra("item_id", item.id)
            val pending = PendingIntent.getActivity(applicationContext, item.id.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            manager.notify(item.id.hashCode(), NotificationCompat.Builder(applicationContext, ReturnsService.CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(ContextCompat.getColor(applicationContext, R.color.laterbox_accent))
                .setContentTitle("Time to return to this").setContentText(item.title).setContentIntent(pending).setAutoCancel(true).build())
        }
        return Result.success()
    }
}
