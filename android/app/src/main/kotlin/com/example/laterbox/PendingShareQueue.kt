package com.example.laterbox

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONException

class PendingShareQueue(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("laterbox_pending_shares", Context.MODE_PRIVATE)

    @Synchronized
    fun enqueue(value: String): Boolean {
        val items = readAll().toMutableList()
        items.add(value)
        return write(items)
    }

    @Synchronized
    fun consumeAll(): List<String> {
        val items = readAll()
        prefs.edit().remove(KEY).commit()
        return items
    }

    @Synchronized
    fun size(): Int = readAll().size

    private fun readAll(): List<String> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return try {
            val array = org.json.JSONArray(raw)
            (0 until array.length()).map { array.getString(it) }
        } catch (error: JSONException) {
            emptyList()
        }
    }

    private fun write(items: List<String>): Boolean {
        val array = org.json.JSONArray()
        items.forEach { array.put(it) }
        return prefs.edit().putString(KEY, array.toString()).commit()
    }

    companion object {
        private const val KEY = "pendingShares"
    }
}
