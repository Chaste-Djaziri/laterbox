package com.example.laterbox.data

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.UUID

val POPULAR_REACTIONS = listOf("👍", "❤️", "💡", "🔥", "🚀", "👏")

data class ItemThreadEntry(
    val id: String = "entry-${System.currentTimeMillis()}-${UUID.randomUUID().toString().take(5)}",
    val type: String = "message",
    val authorName: String? = "Me",
    val content: String,
    val createdAt: String = Instant.now().toString(),
    val updatedAt: String? = null,
    val attachedToId: String? = null,
    val attachedSnippet: String? = null,
    val reactions: Map<String, Int> = emptyMap(),
    val userReactions: List<String> = emptyList()
) {
    val formattedRelativeTime: String
        get() {
            return try {
                val parsed = Instant.parse(createdAt)
                val now = Instant.now()
                val seconds = ChronoUnit.SECONDS.between(parsed, now)
                when {
                    seconds < 60 -> "Just now"
                    seconds < 3600 -> "${seconds / 60}m ago"
                    seconds < 86400 -> "${seconds / 3600}h ago"
                    seconds < 604800 -> "${seconds / 86400}d ago"
                    else -> DateTimeFormatter.ofPattern("MMM d").withZone(ZoneId.systemDefault()).format(parsed)
                }
            } catch (_: Exception) {
                "Recently"
            }
        }
}

data class ItemThreadData(
    val version: Int = 1,
    val entries: List<ItemThreadEntry> = emptyList(),
    val rootReactions: Map<String, Int> = emptyMap(),
    val rootUserReactions: List<String> = emptyList()
)

object ItemThreadParser {
    fun parse(noteContent: String?): ItemThreadData {
        val raw = noteContent?.trim().orEmpty()
        if (raw.isBlank()) return ItemThreadData()

        if ((raw.startsWith("{") && raw.endsWith("}")) || (raw.startsWith("[") && raw.endsWith("]"))) {
            try {
                val json = JSONObject(raw)
                val version = json.optInt("version", 1)
                val entriesList = mutableListOf<ItemThreadEntry>()
                val entriesArray = json.optJSONArray("entries") ?: JSONArray()
                for (i in 0 until entriesArray.length()) {
                    val obj = entriesArray.optJSONObject(i) ?: continue
                    val reactionsMap = mutableMapOf<String, Int>()
                    obj.optJSONObject("reactions")?.let { rObj ->
                        val keys = rObj.keys()
                        while (keys.hasNext()) {
                            val k = keys.next()
                            reactionsMap[k] = rObj.optInt(k, 1)
                        }
                    }
                    val userReactionsList = mutableListOf<String>()
                    obj.optJSONArray("userReactions")?.let { uArr ->
                        for (j in 0 until uArr.length()) {
                            userReactionsList.add(uArr.optString(j))
                        }
                    }
                    fun JSONObject.cleanOptString(key: String): String? {
                        if (isNull(key)) return null
                        val s = optString(key).trim()
                        return if (s.isEmpty() || s.equals("null", ignoreCase = true) || s.equals("undefined", ignoreCase = true)) null else s
                    }
                    val content = obj.cleanOptString("content") ?: ""
                    entriesList.add(
                        ItemThreadEntry(
                            id = obj.cleanOptString("id") ?: "entry-${System.currentTimeMillis()}-$i",
                            type = obj.cleanOptString("type") ?: "message",
                            authorName = obj.cleanOptString("authorName") ?: "Me",
                            content = content,
                            createdAt = obj.cleanOptString("createdAt") ?: Instant.now().toString(),
                            updatedAt = obj.cleanOptString("updatedAt"),
                            attachedToId = obj.cleanOptString("attachedToId"),
                            attachedSnippet = obj.cleanOptString("attachedSnippet"),
                            reactions = reactionsMap,
                            userReactions = userReactionsList
                        )
                    )
                }

                val rootReactionsMap = mutableMapOf<String, Int>()
                json.optJSONObject("rootReactions")?.let { rObj ->
                    val keys = rObj.keys()
                    while (keys.hasNext()) {
                        val k = keys.next()
                        rootReactionsMap[k] = rObj.optInt(k, 1)
                    }
                }
                val rootUserReactionsList = mutableListOf<String>()
                json.optJSONArray("rootUserReactions")?.let { uArr ->
                    for (j in 0 until uArr.length()) {
                        rootUserReactionsList.add(uArr.optString(j))
                    }
                }

                return ItemThreadData(
                    version = version,
                    entries = entriesList,
                    rootReactions = rootReactionsMap,
                    rootUserReactions = rootUserReactionsList
                )
            } catch (_: Exception) {
                // fallback to plain text note below
            }
        }

        return ItemThreadData(
            entries = listOf(
                ItemThreadEntry(
                    id = "initial-note",
                    type = "note",
                    authorName = "Note",
                    content = raw,
                    createdAt = Instant.now().toString()
                )
            )
        )
    }

    fun serialize(thread: ItemThreadData): String {
        if (thread.entries.isEmpty() && thread.rootReactions.isEmpty() && thread.rootUserReactions.isEmpty()) {
            return ""
        }
        return try {
            val json = JSONObject()
            json.put("version", thread.version)

            val entriesArray = JSONArray()
            thread.entries.forEach { entry ->
                val entryObj = JSONObject()
                entryObj.put("id", entry.id)
                entryObj.put("type", entry.type)
                entryObj.put("authorName", entry.authorName ?: "Me")
                entryObj.put("content", entry.content)
                entryObj.put("createdAt", entry.createdAt)
                entry.updatedAt?.let { entryObj.put("updatedAt", it) }
                entry.attachedToId?.let { entryObj.put("attachedToId", it) }
                entry.attachedSnippet?.let { entryObj.put("attachedSnippet", it) }

                val reactionsObj = JSONObject()
                entry.reactions.forEach { (k, v) -> reactionsObj.put(k, v) }
                entryObj.put("reactions", reactionsObj)

                val userReactionsArr = JSONArray()
                entry.userReactions.forEach { userReactionsArr.put(it) }
                entryObj.put("userReactions", userReactionsArr)

                entriesArray.put(entryObj)
            }
            json.put("entries", entriesArray)

            val rootReactionsObj = JSONObject()
            thread.rootReactions.forEach { (k, v) -> rootReactionsObj.put(k, v) }
            json.put("rootReactions", rootReactionsObj)

            val rootUserReactionsArr = JSONArray()
            thread.rootUserReactions.forEach { rootUserReactionsArr.put(it) }
            json.put("rootUserReactions", rootUserReactionsArr)

            json.toString()
        } catch (_: Exception) {
            ""
        }
    }

    fun addEntry(
        thread: ItemThreadData,
        authorName: String = "Me",
        content: String,
        attachedSnippet: String? = null
    ): ItemThreadData {
        val entry = ItemThreadEntry(
            authorName = authorName,
            content = content,
            attachedSnippet = attachedSnippet
        )
        return thread.copy(entries = thread.entries + entry)
    }

    fun deleteEntry(thread: ItemThreadData, id: String): ItemThreadData {
        return thread.copy(entries = thread.entries.filterNot { it.id == id })
    }

    fun toggleThreadReaction(
        thread: ItemThreadData,
        entryId: String,
        emoji: String
    ): ItemThreadData {
        val updatedEntries = thread.entries.map { entry ->
            if (entry.id != entryId) return@map entry

            val reactions = entry.reactions.toMutableMap()
            val userReactions = entry.userReactions.toMutableList()
            val alreadyReacted = userReactions.contains(emoji)

            if (alreadyReacted) {
                userReactions.remove(emoji)
                val current = reactions[emoji] ?: 1
                if (current <= 1) {
                    reactions.remove(emoji)
                } else {
                    reactions[emoji] = current - 1
                }
            } else {
                userReactions.add(emoji)
                reactions[emoji] = (reactions[emoji] ?: 0) + 1
            }

            entry.copy(reactions = reactions, userReactions = userReactions)
        }
        return thread.copy(entries = updatedEntries)
    }

    fun toggleRootReaction(thread: ItemThreadData, emoji: String): ItemThreadData {
        val reactions = thread.rootReactions.toMutableMap()
        val userReactions = thread.rootUserReactions.toMutableList()
        val alreadyReacted = userReactions.contains(emoji)

        if (alreadyReacted) {
            userReactions.remove(emoji)
            val current = reactions[emoji] ?: 1
            if (current <= 1) {
                reactions.remove(emoji)
            } else {
                reactions[emoji] = current - 1
            }
        } else {
            userReactions.add(emoji)
            reactions[emoji] = (reactions[emoji] ?: 0) + 1
        }

        return thread.copy(rootReactions = reactions, rootUserReactions = userReactions)
    }
}
