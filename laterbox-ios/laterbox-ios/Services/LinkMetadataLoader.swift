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
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return true }
        let lower = title.lowercased()
        return lower == "youtube" ||
               lower.contains("video playlist") ||
               lower == "untitled" ||
               lower.hasPrefix("http://") ||
               lower.hasPrefix("https://") ||
               lower == "watch" ||
               lower == "before you continue to youtube"
    }

    public static func load(_ url: URL) async throws -> Metadata {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { throw URLError(.badURL) }

        // 1. Query Next.js web /api/enrich for rich social graphs, rotating bot UAs, and OG images
        if var enriched = await fetchFromEnrichAPI(url) {
            if isGenericTitle(enriched.title), let oembed = await fetchOEmbed(url) {
                enriched.title = oembed.title ?? enriched.title
                enriched.image = oembed.image ?? enriched.image
                enriched.site = oembed.site ?? enriched.site
                if enriched.description == nil || enriched.description?.isEmpty == true {
                    enriched.description = oembed.description
                }
                if !oembed.keywords.isEmpty {
                    let merged = Set(enriched.keywords + oembed.keywords)
                    enriched.keywords = Array(merged).sorted()
                }
            }
            return enriched
        }

        // 2. Fast-path direct oEmbed for media platforms (YouTube, Vimeo)
        if let oembed = await fetchOEmbed(url) {
            return oembed
        }

        // 3. Fall back to local HTML scraper
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

            let title = (json["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let author = (json["author_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let thumb = (json["thumbnail_url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let provider = (json["provider_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? (host.contains("youtube") ? "YouTube" : host)

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
                    .filter { $0.count > 2 && $0.count < 35 && $0 != "playlist" && $0 != "video playlist" }
                tags.append(contentsOf: parts)
            }

            let uniqueTags = Array(Set(tags)).sorted()
            let desc = author.map { "\(provider) by \($0)" } ?? "\(provider) content"

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
