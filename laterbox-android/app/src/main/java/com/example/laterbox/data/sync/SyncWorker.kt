package com.example.laterbox.data.sync

import android.content.Context
import androidx.room.withTransaction
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.laterbox.data.api.LaterBoxApiService
import com.example.laterbox.data.local.*
import com.example.laterbox.services.*
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

class SyncWorker(context: Context, parameters: WorkerParameters) : CoroutineWorker(context, parameters) {
    override suspend fun doWork(): Result {
        return try {
            SyncCoordinator.pullAndPushChanges(applicationContext)
            Result.success()
        } catch (error: kotlinx.coroutines.CancellationException) {
            throw error
        } catch (error: Exception) {
            Result.retry()
        }
    }
}
