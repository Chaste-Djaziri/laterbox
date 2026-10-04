package com.example.laterbox.data

import android.content.Context
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.example.laterbox.data.local.AppDatabase
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.data.sync.SyncWorker
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

interface DataRepository {
    val items: Flow<List<ItemEntity>>
    fun syncNow()
}

class DefaultDataRepository(
    private val context: Context,
    private val database: AppDatabase
) : DataRepository {

    override val items: Flow<List<ItemEntity>> = database.itemDao().watchAllItems()

    override fun syncNow() {
        val syncRequest = OneTimeWorkRequestBuilder<SyncWorker>().build()
        WorkManager.getInstance(context).enqueue(syncRequest)
    }
}
