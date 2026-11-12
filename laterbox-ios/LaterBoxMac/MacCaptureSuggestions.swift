// laterbox-ios/LaterBoxMac/MacCaptureSuggestions.swift
import Foundation
import Security

struct MacLinkPreview: Sendable {
    let title: String
    let description: String
    let domain: String
    let siteName: String
    let imageURL: URL?
    let tags: [String]
    let contentType: String
    let author: String?
}

enum MacCaptureSuggestions {
    private static let keywordGroups: [(String, [String])] = [
        ("Reading", ["article", "book", "blog", "reading", "essay", "research", "documentation"]),
        ("Work", ["meeting", "project", "client", "presentation", "deadline", "report", "office"]),
        ("Urgent", ["urgent", "asap", "deadline", "due today"]),
        ("Personal", ["family", "groceries", "shopping", "appointment", "personal"]),
        ("Finance", ["finance", "invoice", "budget", "payment", "bank", "tax"]),
        ("Inspiration", ["inspiration", "design", "creative", "sketch", "portfolio"]),
        ("Learning", ["tutorial", "lesson", "course", "learn", "guide", "programming"]),
        ("Music", ["music", "song", "piano", "album", "concert"]),
        ("Technology", ["software", "coding", "developer", "github", "technology"])
    ]

    static func tags(for text: String, kind: String, preview: MacLinkPreview? = nil) -> [String] {
        var tags: [String] = []
        if preview?.siteName.lowercased() == "youtube" { tags.append("YouTube") }
        switch preview?.contentType {
        case "video": tags.append("Video")
        case "music": tags.append("Music")
        case "article": tags.append("Reading")
        case "repository": tags.append("Development")
        default: break
        }
        tags.append(contentsOf: preview?.tags ?? [])
        for (label, terms) in keywordGroups {
            let lower = text.lowercased()
            if terms.contains(where: { term in
                lower.range(of: #"(?<![a-z])"# + NSRegularExpression.escapedPattern(for: term) + #"(?![a-z])"#,
                            options: .regularExpression) != nil
            }) { tags.append(label) }
        }
        if kind == "Link" && tags.isEmpty { tags.append("Reading") }
        var seen = Set<String>()
        return tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            .prefix(6).map { $0 }
    }

    static func returnSuggestion(for text: String, kind: String, contentType: String? = nil) -> (preset: String, reason: String) {
        let words = text.lowercased()
        for (expression, preset, reason) in [
            (#"\b(next week|in one week|in a week|7 days)\b"#, "Next week", "You mentioned next week."),
            (#"\b(weekend|saturday|sunday)\b"#, "This weekend", "You mentioned the weekend."),
            (#"\b(today|tonight|asap|urgent|this afternoon|this evening)\b"#, "Later today", "This sounds time-sensitive."),
            (#"\btomorrow\b"#, "Tomorrow", "You mentioned tomorrow."),
            (#"\b(someday|no rush|no deadline|whenever)\b"#, "Someday", "No deadline was mentioned.")
        ] {
            if words.range(of: expression, options: .regularExpression) != nil { return (preset, reason) }
        }
        if contentType == "video" || contentType == "music" {
            return ("This weekend", "Suggested time to watch or listen.")
        }
        if kind == "Link" { return ("This weekend", "Suggested time to revisit saved content.") }
        if kind == "Note" { return ("Someday", "Notes don't need a reminder by default.") }
        return ("Tomorrow", "Suggested time to revisit this.")
    }

    static func normalizedURL(_ text: String) -> URL? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: clean), ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil else { return nil }
        return url
    }

    static func fetchLink(_ url: URL) async throws -> MacLinkPreview {
        guard allowedPublicURL(url) else { throw URLError(.unsupportedURL) }
        let host = url.host!.lowercased().replacingOccurrences(of: "www.", with: "")
        let isYouTube = host == "youtu.be" || host == "youtube.com" || host.hasSuffix(".youtube.com")
        let type = isYouTube || host == "vimeo.com" ? "video" :
                   host.contains("spotify.com") || host.contains("soundcloud.com") ? "music" :
                   host == "github.com" || host == "gitlab.com" ? "repository" : "article"

        // Try the same enrichment service as Laterbox Web. This covers
        // social/video URLs that block raw HTML fetching by native clients.
        async let webPreview = fetchWebEnrichment(url)
        async let mediaPreview = fetchOEmbed(url)
        let web = try? await webPreview
        let media = try? await mediaPreview

        let remoteTitle = media?.title ?? web?.title
        let remoteDescription = web?.description ?? media?.description
        let remoteImage = web?.imageURL ?? media?.imageURL
        let remoteTags = web?.tags ?? []
        if let remoteTitle, !isGenericTitle(remoteTitle), remoteTitle.lowercased() != host, !remoteTitle.isEmpty {
            return MacLinkPreview(
                title: remoteTitle, description: remoteDescription ?? "",
                domain: host, siteName: web?.siteName ?? media?.siteName ?? host,
                imageURL: remoteImage ?? youtubeThumbnail(url),
                tags: remoteTags, contentType: web?.contentType ?? type,
                author: web?.author ?? media?.author
            )
        }

        // Fallback for sites where the Web endpoint is unavailable.
        if let html = try? await fetchHTML(url) {
            let title = meta(html, "og:title") ?? meta(html, "twitter:title") ?? titleTag(html)
            let description = meta(html, "og:description") ?? meta(html, "twitter:description") ?? meta(html, "description") ?? ""
            let image = meta(html, "og:image").flatMap { URL(string: $0, relativeTo: url)?.absoluteURL }
            if let title, !isGenericTitle(title) {
                let keywords = meta(html, "keywords").map { Array($0.components(separatedBy: ",").prefix(5)) } ?? []
                return MacLinkPreview(title: title, description: description, domain: host,
                                      siteName: meta(html, "og:site_name") ?? host,
                                      imageURL: image ?? youtubeThumbnail(url), tags: keywords,
                                      contentType: type, author: meta(html, "author"))
            }
        }

        if isYouTube, let videoID = youtubeID(url) {
            return MacLinkPreview(title: "YouTube video", description: "Video ID: \(videoID)",
                                  domain: host, siteName: "YouTube",
                                  imageURL: youtubeThumbnail(url),
                                  tags: ["YouTube", "Video"], contentType: "video", author: nil)
        }
        throw URLError(.cannotParseResponse)
    }

    private struct Remote: Sendable {
        var title: String?
        var description: String?
        var siteName: String?
        var imageURL: URL?
        var tags: [String]
        var contentType: String?
        var author: String?
    }

    private static func fetchWebEnrichment(_ url: URL) async throws -> Remote {
        var request = URLRequest(url: URL(string: "https://laterbox.dev/api/enrich")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 7
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["url": url.absoluteString])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        let classification = obj["classification"] as? [String: Any]
        return Remote(title: obj["title"] as? String,
                      description: obj["description"] as? String,
                      siteName: (obj["siteName"] ?? obj["site_name"]) as? String,
                      imageURL: ((obj["previewImageUrl"] ?? obj["preview_image_url"]) as? String).flatMap(URL.init(string:)),
                      tags: obj["keywords"] as? [String] ?? [],
                      contentType: (classification?["contentType"] ?? obj["content_type"]) as? String,
                      author: obj["author"] as? String)
    }

    private static func fetchOEmbed(_ url: URL) async throws -> Remote {
        let host = (url.host ?? "").lowercased()
        let endpoint: String
        if host == "youtu.be" || host == "youtube.com" || host.hasSuffix(".youtube.com") {
            endpoint = "https://www.youtube.com/oembed?format=json&url="
        } else if host == "vimeo.com" || host.hasSuffix(".vimeo.com") {
            endpoint = "https://vimeo.com/api/oembed.json?url="
        } else if host == "open.spotify.com" {
            endpoint = "https://open.spotify.com/oembed?url="
        } else if host == "soundcloud.com" {
            endpoint = "https://soundcloud.com/oembed?format=json&url="
        } else { throw URLError(.unsupportedURL) }
        var request = URLRequest(url: URL(string: endpoint + (url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""))!)
        request.timeoutInterval = 7
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        let author = obj["author_name"] as? String
        return Remote(title: obj["title"] as? String,
                      description: obj["description"] as? String ?? author.map { "By \($0)" },
                      siteName: obj["provider_name"] as? String,
                      imageURL: (obj["thumbnail_url"] as? String).flatMap(URL.init(string:)),
                      tags: [], contentType: nil, author: author)
    }

    private static func fetchHTML(_ url: URL) async throws -> String {
        var req = URLRequest(url: url)
        req.timeoutInterval = 9
        req.setValue("text/html", forHTTPHeaderField: "Accept")
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              http.mimeType?.contains("html") == true, data.count < 1_500_000 else {
            throw URLError(.cannotParseResponse)
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func meta(_ html: String, _ name: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: #"(?is)<meta\b[^>]*>"#) else { return nil }
        for m in expression.matches(in: html, range: NSRange(html.startIndex..., in: html)).prefix(200) {
            guard let range = Range(m.range, in: html) else { continue }
            let attributes = String(html[range])
            func field(_ attr: String) -> String? {
                let pattern = #"(?i)\b"# + NSRegularExpression.escapedPattern(for: attr) + #"\s*=\s*(["'])(.*?)\1"#
                guard let expression = try? NSRegularExpression(pattern: pattern),
                      let found = expression.firstMatch(in: attributes,
                          range: NSRange(attributes.startIndex..., in: attributes)),
                      let valueRange = Range(found.range(at: 2), in: attributes) else { return nil }
                return String(attributes[valueRange])
            }
            if field("property")?.lowercased() == name || field("name")?.lowercased() == name,
               let value = field("content"), !value.isEmpty { return clean(value) }
        }
        return nil
    }

    private static func titleTag(_ html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"(?is)<title\b[^>]*>(.*?)</title>"#),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(match.range(at: 1), in: html) else { return nil }
        return clean(String(html[r]))
    }

    private static func clean(_ text: String) -> String {
        var result = text
        for (key, value) in [("&amp;", "&"), ("&quot;", "\""), ("&#39;", "'"), ("&lt;", "<"), ("&gt;", ">"), ("&nbsp;", " ")] {
            result = result.replacingOccurrences(of: key, with: value)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isGenericTitle(_ value: String) -> Bool {
        let lower = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return lower.isEmpty || ["youtube", "youtube.com", "youtu.be", "watch", "before you continue to youtube", "untitled"].contains(lower)
    }

    private static func youtubeID(_ url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        var candidate: String?
        if host == "youtu.be" { candidate = url.pathComponents.dropFirst().first }
        else if host == "youtube.com" || host.hasSuffix(".youtube.com") {
            if url.path == "/watch" { candidate = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "v" })?.value }
            else if url.path.hasPrefix("/shorts/") || url.path.hasPrefix("/embed/") || url.path.hasPrefix("/live/") {
                candidate = url.pathComponents.dropFirst(2).first
            }
        }
        guard let candidate, candidate.range(of: #"^[a-zA-Z0-9_-]{11}$"#, options: .regularExpression) != nil else { return nil }
        return candidate
    }

    private static func youtubeThumbnail(_ url: URL) -> URL? {
        youtubeID(url).flatMap { URL(string: "https://i.ytimg.com/vi/\($0)/hqdefault.jpg") }
    }

    private static func allowedPublicURL(_ url: URL) -> Bool {
        guard ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host?.lowercased(), !host.isEmpty,
              host != "localhost", !host.hasSuffix(".local"), !host.hasSuffix(".internal"),
              !host.contains(":"), !host.hasPrefix("127."), !host.hasPrefix("10."),
              !host.hasPrefix("192.168."), !host.hasPrefix("169.254.") else { return false }
        let parts = host.split(separator: ".")
        if parts.count == 4, let first = Int(parts[0]), let second = Int(parts[1]) {
            if first == 172 && (16...31).contains(second) { return false }
            if first == 0 || first == 100 || first >= 224 { return false }
        }
        return true
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
