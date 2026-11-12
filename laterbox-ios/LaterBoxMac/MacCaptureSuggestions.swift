// laterbox-ios/LaterBoxMac/MacCaptureSuggestions.swift
import Foundation
import Security

struct MacLinkPreview: Sendable {
    let title: String
    let description: String
    let domain: String
}

enum MacCaptureSuggestions {
    private static let keywords: [(tag: String, terms: [String])] = [
        ("Reading", ["read", "article", "book", "blog", "newsletter", "research", "documentation"]),
        ("Work", ["work", "meeting", "project", "client", "presentation", "deadline", "report"]),
        ("Urgent", ["urgent", "asap", "due today", "important"]),
        ("Personal", ["personal", "family", "groceries", "shopping", "appointment"]),
        ("Finance", ["finance", "invoice", "budget", "bill", "payment", "bank", "tax"]),
        ("Inspiration", ["idea", "inspiration", "design", "creative", "sketch"])
    ]

    static func tags(for text: String, kind: String) -> [String] {
        let lower = text.lowercased()
        var found = keywords.filter { entry in
            entry.terms.contains { term in
                lower.range(of: term, options: .regularExpression) != nil
            }
        }.map(\.tag)
        if kind == "Link", found.isEmpty {
            found = ["Reading"]
        }
        return Array(found.prefix(3))
    }

    static func returnSuggestion(for text: String, kind: String) -> (preset: String, reason: String) {
        let words = text.lowercased()
        if words.range(of: #"\b(next week|in one week|in a week|7 days)\b"#, options: .regularExpression) != nil {
            return ("Next week", "You mentioned next week.")
        }
        if words.range(of: #"\b(weekend|saturday|sunday)\b"#, options: .regularExpression) != nil {
            return ("This weekend", "You mentioned the weekend.")
        }
        if words.range(of: #"\b(today|tonight|asap|urgent|this afternoon|this evening)\b"#, options: .regularExpression) != nil {
            return ("Later today", "This sounds time-sensitive.")
        }
        if words.range(of: #"\btomorrow\b"#, options: .regularExpression) != nil {
            return ("Tomorrow", "You mentioned tomorrow.")
        }
        if words.range(of: #"\b(someday|no rush|no deadline|whenever)\b"#, options: .regularExpression) != nil {
            return ("Someday", "No deadline was mentioned.")
        }
        if kind == "Link" { return ("This weekend", "A relaxed time to revisit saved links.") }
        if kind == "Note" { return ("Someday", "Notes can stay available without a reminder.") }
        return ("Tomorrow", "A useful time to revisit this.")
    }

    // Fetch only public HTTPS pages. Avoid opening file:, localhost or private-IP
    // URLs. Limit response size and reject non-HTML responses.
    static func fetchLink(_ url: URL) async throws -> MacLinkPreview {
        guard url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty,
              host != "localhost", !host.hasSuffix(".local"),
              !host.hasSuffix(".internal"),
              !host.hasPrefix("127."), !host.hasPrefix("10."),
              !host.hasPrefix("192.168."), !host.hasPrefix("169.254."),
              !host.hasPrefix("172."), !host.contains(":") else {
            throw URLError(.unsupportedURL)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        req.setValue("text/html", forHTTPHeaderField: "Accept")
        req.setValue("Laterbox/1.0 (link preview)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              http.mimeType?.lowercased().contains("html") == true,
              data.count <= 700_000 else { throw URLError(.cannotParseResponse) }
        let html = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        let title = metadata(html, key: "og:title") ?? metadata(html, key: "twitter:title") ?? tagText(html, name: "title") ?? host
        let description = metadata(html, key: "og:description") ?? metadata(html, key: "description") ?? ""
        return MacLinkPreview(title: clean(title), description: clean(description), domain: host)
    }

    private static func metadata(_ html: String, key: String) -> String? {
        let pattern = #"(?is)<meta\b[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        for match in regex.matches(in: html, range: range).prefix(120) {
            guard let r = Range(match.range, in: html) else { continue }
            let tag = String(html[r])
            let fields = attributes(tag)
            if fields["property"]?.lowercased() == key || fields["name"]?.lowercased() == key {
                return fields["content"]
            }
        }
        return nil
    }

    private static func attributes(_ tag: String) -> [String: String] {
        let pattern = #"(?i)([\w:-]+)\s*=\s*["']([^"']*)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [:] }
        var fields: [String: String] = [:]
        for match in regex.matches(in: tag, range: NSRange(tag.startIndex..., in: tag)) {
            if let k = Range(match.range(at: 1), in: tag),
               let v = Range(match.range(at: 2), in: tag) {
                fields[String(tag[k]).lowercased()] = String(tag[v])
            }
        }
        return fields
    }

    private static func tagText(_ html: String, name: String) -> String? {
        let pattern = "(?is)<" + name + #"\b[^>]*>(.*?)</"# + name + ">"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }

    private static func clean(_ text: String) -> String {
        var value = text
        for (entity, replacement) in [("&amp;", "&"), ("&quot;", "\""), ("&#39;", "'"), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " ")] {
            value = value.replacingOccurrences(of: entity, with: replacement)
        }
        return String(value.replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines).prefix(220))
    }
}

struct MacCloudCollection: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
}

enum MacCollectionLookup {
    static func fetch() async throws -> [MacCloudCollection] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "laterbox-macos-session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let sessionData = result as? Data,
              let credentials = try? JSONDecoder().decode([String: String].self, from: sessionData),
              let token = credentials["access_token"], !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        let endpoint = "https://ltjisrgldssqskcylcbj.supabase.co/rest/v1/collections?select=id,name&deleted_at=is.null&order=name.asc"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.setValue("sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p", forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([MacCloudCollection].self, from: data)
    }
}
