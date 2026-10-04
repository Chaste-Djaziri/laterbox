import Foundation
import NaturalLanguage

/// Shared, entirely local ranking. No generated result can become a library item.
@MainActor
public enum LocalItemSearch {
    private static let embedding = NLEmbedding.wordEmbedding(for: .english)
    private static var cache: [String: (Date, String)] = [:]
    private static let noise: Set<String> = ["the", "that", "about", "find", "my", "saved", "something", "a", "an", "for", "me", "show"]

    public static func search(_ query: String, in items: [LBItem], includeDeleted: Bool = false) -> [LBItem] {
        let eligible = items.filter { includeDeleted || $0.status != "deleted" }
        let q = normalize(query)
        guard !q.isEmpty else { return eligible }
        let terms = q.split(separator: " ").map(String.init).filter { !noise.contains($0) }
        guard !terms.isEmpty else { return [] }
        return eligible.compactMap { item -> (LBItem, Double)? in
            let text: String
            if let entry = cache[item.id], entry.0 == item.updatedAt { text = entry.1 }
            else {
                text = normalize([item.title, item.textContent ?? "", item.noteContent ?? "", item.url ?? "", item.domain ?? "", item.tags.joined(separator: " "), item.category, item.summary, item.formattedContent, item.collectionName ?? ""].joined(separator: " "))
                cache[item.id] = (item.updatedAt, text)
            }
            let words = Array(Set(text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))).prefix(400)
            var score = text.contains(q) ? 12.0 : 0
            var hits = 0
            for term in terms {
                if text.contains(term) { score += normalize(item.title).contains(term) ? 5 : 3; hits += 1; continue }
                if term.count >= 4 && words.contains(where: { editDistance(term, $0) <= 1 }) { score += 2; hits += 1; continue }
                if let embedding, embedding.contains(term), words.contains(where: { embedding.contains($0) && embedding.distance(between: term, and: $0) < 0.65 }) { score += 1; hits += 1 }
            }
            guard hits > 0 else { return nil }
            return (item, score + Double(hits) / Double(terms.count))
        }.sorted { $0.1 == $1.1 ? $0.0.createdAt > $1.0.createdAt : $0.1 > $1.1 }.map(\.0)
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()
    }
    static func editDistance(_ a: String, _ b: String) -> Int {
        guard abs(a.count - b.count) <= 1 else { return 2 }
        let rhs = Array(b)
        var previous = Array(0...rhs.count)
        for (i, character) in a.enumerated() {
            var row = [i + 1]
            for (j, other) in rhs.enumerated() { row.append(min(row[j] + 1, previous[j + 1] + 1, previous[j] + (character == other ? 0 : 1))) }
            previous = row
        }
        return previous.last ?? 0
    }
}
