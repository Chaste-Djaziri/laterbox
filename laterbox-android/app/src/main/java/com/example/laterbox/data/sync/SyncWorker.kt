package com.example.laterbox.data.sync

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.laterbox.SupabaseClient
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import io.github.jan.supabase.postgrest.postgrest
import java.time.Instant
import java.time.format.DateTimeFormatter

class SyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val database = AppDatabase.getDatabase(applicationContext)
        val itemDao = database.itemDao()
        val supabase = SupabaseClient.client

        return try {
            // 1. Push pending items to Supabase
            val pendingItems = itemDao.getItemsNeedingSync()
            if (pendingItems.isNotEmpty()) {
                // Upsert to Supabase
                supabase.postgrest["items"].upsert(pendingItems)

                // Mark as synced
                val now = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
                pendingItems.forEach { item ->
                    itemDao.markSynced(item.id, now)
                }
            }

            // 2. Pull remote items from Supabase
            val remoteItems = supabase.postgrest["items"]
                .select()
                .decodeList<ItemEntity>()

            if (remoteItems.isNotEmpty()) {
                itemDao.insertItems(remoteItems.map { it.copy(syncStatus = "synced") })
            }

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.retry()
        }
    }
}
