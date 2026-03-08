import Foundation

// HTML 转可读文本，避免在主线程做高成本解析
struct HTMLContentRenderer {
    static func plainText(from html: String?) -> String {
        guard let html, !html.isEmpty else { return "" }
        return html
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func detectMentions(in text: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "@([A-Za-z0-9_\\-]+)")
        let ns = text as NSString
        let results = regex?.matches(in: text, range: NSRange(location: 0, length: ns.length)) ?? []
        return results.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return ns.substring(with: match.range(at: 1))
        }
    }
}
