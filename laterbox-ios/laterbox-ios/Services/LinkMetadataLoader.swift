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

    public static func load(_ url: URL) async throws -> Metadata {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { throw URLError(.badURL) }

        // 1. Query Next.js web /api/enrich for rich social graphs, rotating bot UAs, and OG images
        if let enriched = await fetchFromEnrichAPI(url) {
            return enriched
        }

        // 2. Fall back to local HTML scraper
        return try await fetchLocalScrape(url)
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
