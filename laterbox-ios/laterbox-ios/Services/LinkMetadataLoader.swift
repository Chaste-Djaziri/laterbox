import Foundation

enum LinkMetadataLoader {
    struct Metadata { var site: String?; var description: String?; var image: String? }
    static func load(_ url: URL) async throws -> Metadata {
        guard ["http", "https"].contains(url.scheme ?? "") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), response.mimeType?.contains("html") == true else { throw URLError(.badServerResponse) }
        var data = Data()
        for try await byte in bytes { data.append(byte); if data.count >= 512_000 { break } }
        let html = String(decoding: data, as: UTF8.self)
        func meta(_ key: String) -> String? {
            let pattern = "<meta\\b[^>]*(?:property|name)=[\"']" + NSRegularExpression.escapedPattern(for: key) + "[\"'][^>]*content=[\"']([^\"']*)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive), let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)), let range = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[range]).replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&quot;", with: "\"")
        }
        let image = meta("og:image").flatMap { URL(string: $0, relativeTo: response.url ?? url)?.absoluteURL }.flatMap { ["http", "https"].contains($0.scheme ?? "") ? $0.absoluteString : nil }
        return Metadata(site: meta("og:site_name") ?? url.host, description: meta("og:description") ?? meta("description"), image: image)
    }
}
