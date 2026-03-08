import Foundation

enum ImageURLNormalizer {
    static func normalizedURL(from raw: String?, baseURL: URL? = URL(string: "https://www.v2ex.com")) -> URL? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        value = value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")

        if value.hasPrefix("//") {
            value = "https:\(value)"
        } else if value.hasPrefix("/") {
            if let baseURL {
                value = baseURL.appendingPathComponent(String(value.dropFirst())).absoluteString
            }
        } else if !value.contains("://") {
            value = "https://\(value)"
        }

        guard var components = URLComponents(string: value) else { return nil }
        if components.scheme?.lowercased() == "http" {
            components.scheme = "https"
        }
        if components.percentEncodedPath.isEmpty {
            components.percentEncodedPath = "/"
        }
        return components.url
    }
}

extension URL {
    var isLikelyImageURL: Bool {
        let ext = pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp", "avif"].contains(ext) {
            return true
        }
        let lowerPath = path.lowercased()
        if lowerPath.contains("/image") || lowerPath.contains("/img") || lowerPath.contains("/photo") {
            return true
        }
        if let query = query?.lowercased(),
           query.contains("format=jpg")
            || query.contains("format=jpeg")
            || query.contains("format=png")
            || query.contains("format=webp")
            || query.contains("image") {
            return true
        }
        return false
    }
}
