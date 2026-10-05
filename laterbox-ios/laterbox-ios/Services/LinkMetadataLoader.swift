import Foundation

public struct LinkMetadata: Codable {
    public var title: String?
    public var site: String?
    public var description: String?
    public var image: String?
    public var faviconUrl: String?
    public var keywords: [String] = []
    public var contentType: String?

    public init(
        title: String? = nil,
        site: String? = nil,
        description: String? = nil,
        image: String? = nil,
        faviconUrl: String? = nil,
        keywords: [String] = [],
        contentType: String? = nil
    ) {
        self.title = title
        self.site = site
        self.description = description
        self.image = image
        self.faviconUrl = faviconUrl
        self.keywords = keywords
        self.contentType = contentType
    }
}

public enum LinkMetadataLoader {
    public typealias Metadata = LinkMetadata

    private static let webEnrichEndpoint = URL(string: "https://laterbox.dev/api/enrich")!

    public static func isGenericTitle(_ title: String?) -> Bool {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        let stripped = raw.trimmingCharacters(in: CharacterSet(charactersIn: "-–—|: •\t\n\r"))
        let lower = stripped.lowercased()
        return lower.isEmpty ||
               lower == "youtube" ||
               lower == "- youtube" ||
               (lower.hasSuffix("youtube") && lower.count <= 14) ||
               lower == "video playlist" ||
               lower.contains("video playlist") ||
               lower == "untitled" ||
               lower.hasPrefix("http://") ||
               lower.hasPrefix("https://") ||
               lower == "watch" ||
               lower == "watch video" ||
               lower == "before you continue to youtube" ||
               lower == "vimeo" ||
               lower == "spotify" ||
               lower == "soundcloud"
    }

    public static func cleanTitle(_ title: String?) -> String? {
        guard let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
        if isGenericTitle(raw) { return nil }
        var cleaned = raw
        for suffix in [" - YouTube", " | YouTube", " – YouTube", " — YouTube", " - Vimeo", " | Vimeo", " on Spotify"] {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return isGenericTitle(cleaned) ? nil : cleaned
    }

    public static func isGenericDescription(_ desc: String?) -> Bool {
        guard let raw = desc?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return true }
        return raw.contains("enjoy the videos and music you love") ||
               raw.contains("upload original content") ||
               raw.contains("share it all with friends, family")
    }

    public static func load(_ url: URL) async throws -> Metadata {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { throw URLError(.badURL) }

        let host = url.host?.lowercased() ?? ""
        let isMedia = host.contains("youtube.com") || host == "youtu.be" || host.contains("vimeo.com")

        // 1. For media links, query oEmbed concurrently for authentic video title & author
        async let oembedTask = isMedia ? fetchOEmbed(url) : nil
        async let enrichTask = fetchFromEnrichAPI(url)

        let oembed = await oembedTask
        var enriched = await enrichTask

        if var res = enriched {
            let titleIsGeneric = isGenericTitle(res.title) || res.title?.hasSuffix("- YouTube") == true
            if titleIsGeneric, let o = oembed, let realTitle = o.title, !realTitle.isEmpty {
                res.title = realTitle
            } else if let cleaned = cleanTitle(res.title) {
                res.title = cleaned
            }

            if isGenericTitle(res.title), let o = oembed {
                res.title = o.title ?? res.title
            }

            if (res.description == nil || res.description?.isEmpty == true || isGenericDescription(res.description)),
               let o = oembed, let oDesc = o.description, !oDesc.isEmpty {
                res.description = oDesc
            }

            if let o = oembed {
                if res.image == nil || res.image?.isEmpty == true {
                    res.image = o.image
                }
                let junkTags: Set<String> = ["sharing", "camera phone", "video phone", "free", "upload", "playlist", "video playlist"]
                let filteredEnriched = res.keywords.filter { !junkTags.contains($0.lowercased()) }
                let filteredOembed = o.keywords.filter { !junkTags.contains($0.lowercased()) }
                res.keywords = Array(Set(filteredEnriched + filteredOembed)).sorted()
            }

            return res
        }

        if let oembed {
            return oembed
        }

        // 2. Fall back to local HTML scraper
        return try await fetchLocalScrape(url)
    }

    public static func fetchOEmbed(_ url: URL) async -> Metadata? {
        guard let host = url.host?.lowercased() else { return nil }
        var oembedUrlString: String?

        if host.contains("youtube.com") || host == "youtu.be" {
            if let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                oembedUrlString = "https://www.youtube.com/oembed?url=\(encoded)&format=json"
            }
        } else if host.contains("vimeo.com") {
            if let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                oembedUrlString = "https://vimeo.com/api/oembed.json?url=\(encoded)"
            }
        }

        guard let oembedUrlString, let oembedUrl = URL(string: oembedUrlString) else { return nil }

        var request = URLRequest(url: oembedUrl)
        request.timeoutInterval = 6
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            let rawTitle = (json["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let author = (json["author_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let thumb = (json["thumbnail_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let provider = (json["provider_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? (host.contains("youtube") ? "YouTube" : host)

            let title = cleanTitle(rawTitle) ?? rawTitle

            var tags: [String] = []
            if host.contains("youtube") || host == "youtu.be" {
                tags.append(contentsOf: ["video", "youtube"])
            } else if host.contains("vimeo") {
                tags.append(contentsOf: ["video", "vimeo"])
            }
            if let author, !author.isEmpty { tags.append(author.lowercased()) }

            if let title, !title.isEmpty {
                let parts = title.components(separatedBy: CharacterSet(charactersIn: "|-:–—[]()•\""))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { $0.count > 2 && $0.count < 35 && !["playlist", "video playlist", "sharing", "camera phone", "video phone", "free", "upload"].contains($0) }
                tags.append(contentsOf: parts)
            }

            let uniqueTags = Array(Set(tags)).sorted()
            let desc = author.map { "Video by \($0) on \(provider)" } ?? "\(provider) content"

            return Metadata(
                title: (title?.isEmpty == false && !isGenericTitle(title)) ? title : nil,
                site: provider,
                description: desc,
                image: thumb,
                faviconUrl: "https://www.google.com/s2/favicons?domain=\(host)&sz=128",
                keywords: uniqueTags,
                contentType: "video"
            )
        } catch {
            return nil
        }
    }

    private static func fetchFromEnrichAPI(_ url: URL) async -> Metadata? {
        var request = URLRequest(url: webEnrichEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 7
        let payload = ["url": url.absoluteString]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }

            struct ClassificationDTO: Decodable {
                let contentType: String?
                let type: String?
            }

            struct EnrichResponseDTO: Decodable {
                let domain: String?
                let siteName: String?
                let site_name: String?
                let title: String?
                let description: String?
                let faviconUrl: String?
                let favicon_url: String?
                let previewImageUrl: String?
                let preview_image_url: String?
                let keywords: [String]?
                let classification: ClassificationDTO?
            }

            let dto = try JSONDecoder().decode(EnrichResponseDTO.self, from: data)
            let site = dto.siteName ?? dto.site_name ?? dto.domain ?? url.host
            let img = dto.previewImageUrl ?? dto.preview_image_url
            let favicon = dto.faviconUrl ?? dto.favicon_url
            let tags = dto.keywords ?? []
            let cType = dto.classification?.contentType ?? dto.classification?.type

            return Metadata(
                title: dto.title,
                site: site,
                description: dto.description,
                image: img,
                faviconUrl: favicon,
                keywords: tags,
                contentType: cType
            )
        } catch {
            return nil
        }
    }

    private static func fetchLocalScrape(_ url: URL) async throws -> Metadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)", forHTTPHeaderField: "User-Agent")
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), response.mimeType?.contains("html") == true else {
            throw URLError(.badServerResponse)
        }
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count >= 512_000 { break }
        }
        let html = String(decoding: data, as: UTF8.self)
        func decode(_ value: String) -> String {
            value.replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
        }
        func meta(_ key: String) -> String? {
            guard let tags = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: .caseInsensitive),
                  let attributes = try? NSRegularExpression(pattern: "([a-zA-Z:-]+)\\s*=\\s*[\"']([^\"']*)[\"']", options: .caseInsensitive) else { return nil }
            for match in tags.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
                guard let range = Range(match.range, in: html) else { continue }
                let tag = String(html[range])
                var values: [String: String] = [:]
                for attribute in attributes.matches(in: tag, range: NSRange(tag.startIndex..., in: tag)) {
                    if let name = Range(attribute.range(at: 1), in: tag), let value = Range(attribute.range(at: 2), in: tag) {
                        values[String(tag[name]).lowercased()] = decode(String(tag[value]))
                    }
                }
                if (values["property"] ?? values["name"])?.lowercased() == key.lowercased() {
                    return values["content"]
                }
            }
            return nil
        }
        let titleRegex = try? NSRegularExpression(pattern: "<title[^>]*>([^<]*)</title>", options: .caseInsensitive)
        let titleMatch = titleRegex?.firstMatch(in: html, range: NSRange(html.startIndex..., in: html))
        let title = meta("og:title") ?? titleMatch.flatMap { Range($0.range(at: 1), in: html).map { decode(String(html[$0])) } }
        let image = meta("og:image").flatMap { URL(string: $0, relativeTo: response.url ?? url)?.absoluteURL }.flatMap { ["http", "https"].contains($0.scheme ?? "") ? $0.absoluteString : nil }
        let site = meta("og:site_name") ?? url.host
        let description = meta("og:description") ?? meta("description")
        return Metadata(title: title, site: site, description: description, image: image, faviconUrl: nil, keywords: [], contentType: nil)
    }
}
