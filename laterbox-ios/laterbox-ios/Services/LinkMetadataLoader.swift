import Foundation

enum LinkMetadataLoader {
    struct Metadata { var title: String?; var site: String?; var description: String?; var image: String? }
    static func load(_ url: URL) async throws -> Metadata {
        guard ["http", "https"].contains(url.scheme ?? "") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), response.mimeType?.contains("html") == true else { throw URLError(.badServerResponse) }
        var data = Data()
        for try await byte in bytes { data.append(byte); if data.count >= 512_000 { break } }
        let html = String(decoding: data, as: UTF8.self)
        func decode(_ value: String) -> String {
            value.replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&#39;", with: "'")
        }
        func meta(_ key: String) -> String? {
            guard let tags = try? NSRegularExpression(pattern: "<meta\\b[^>]*>", options: .caseInsensitive),
                  let attributes = try? NSRegularExpression(pattern: "([a-zA-Z:-]+)\\s*=\\s*[\"']([^\"']*)[\"']", options: .caseInsensitive) else { return nil }
            for match in tags.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
                guard let range = Range(match.range, in: html) else { continue }
                let tag = String(html[range])
                var values: [String: String] = [:]
                for attribute in attributes.matches(in: tag, range: NSRange(tag.startIndex..., in: tag)) {
                    if let name = Range(attribute.range(at: 1), in: tag), let value = Range(attribute.range(at: 2), in: tag) { values[String(tag[name]).lowercased()] = decode(String(tag[value])) }
                }
                if (values["property"] ?? values["name"])?.lowercased() == key.lowercased() { return values["content"] }
            }
            return nil
        }
        let titleRegex = try? NSRegularExpression(pattern: "<title[^>]*>([^<]*)</title>", options: .caseInsensitive)
        let titleMatch = titleRegex?.firstMatch(in: html, range: NSRange(html.startIndex..., in: html))
        let title = meta("og:title") ?? titleMatch.flatMap { Range($0.range(at: 1), in: html).map { decode(String(html[$0])) } }
        let image = meta("og:image").flatMap { URL(string: $0, relativeTo: response.url ?? url)?.absoluteURL }.flatMap { ["http", "https"].contains($0.scheme ?? "") ? $0.absoluteString : nil }
        return Metadata(title: title, site: meta("og:site_name") ?? url.host, description: meta("og:description") ?? meta("description"), image: image)
    }
}
