package com.example.laterbox.services

import com.example.laterbox.data.local.ItemEntity
import java.text.Normalizer

object LocalSearch {
    private val synonyms = mapOf("watch" to "video", "listen" to "music audio", "read" to "article book reading", "cook" to "recipe food cooking", "work" to "productivity focus job", "learn" to "education tutorial study")
    private fun normalized(text: String) = Normalizer.normalize(text.lowercase(), Normalizer.Form.NFD).replace(Regex("\\p{M}"), "")
    fun search(query: String, items: List<ItemEntity>, includeDeleted: Boolean = false): List<ItemEntity> {
        val words = normalized(query).split(Regex("\\W+")).filter { it.isNotEmpty() && it !in listOf("my", "the", "find", "saved", "things", "about", "to", "for", "me") }
        return items.filter { includeDeleted || it.deletedAt == null }.map { item ->
            val title = normalized(item.title.orEmpty())
            val corpus = normalized(listOf(item.title, item.textContent, item.url, item.tags, item.category, item.summary, item.notes, item.formattedContent, item.type, item.attachments).joinToString(" "))
            val tokens = corpus.split(Regex("\\W+"))
            val score = words.sumOf { word ->
                when {
                    title == word -> 15
                    title.contains(word) -> 10
                    corpus.contains(word) -> 6
                    synonyms[word]?.split(" ")?.any { corpus.contains(it) } == true -> 4
                    word.length >= 4 && tokens.any { it.length >= 4 && distance(word, it) <= if (word.length >= 8) 2 else 1 } -> 2
                    else -> 0
                }
            }
            item to score
        }.filter { words.isEmpty() || it.second > 0 }.sortedByDescending { it.second }.map { it.first }
    }
    fun distance(a: String, b: String): Int {
        var previous = IntArray(b.length + 1) { it }
        a.forEachIndexed { i, ca ->
            val next = IntArray(b.length + 1); next[0] = i + 1
            b.forEachIndexed { j, cb -> next[j + 1] = minOf(next[j] + 1, previous[j + 1] + 1, previous[j] + if (ca == cb) 0 else 1) }
            previous = next
        }
        return previous[b.length]
    }
}
