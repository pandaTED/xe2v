import Foundation

struct NotificationsHTMLParser {
    static func parse(html: String) -> [V2EXNotification] {
        let blocks = captureBlocks(pattern: "(?s)<span class=\\\"snow\\\">(.*?)</span>", in: html)
        guard !blocks.isEmpty else { return [] }

        let now = Int(Date().timeIntervalSince1970)
        return blocks.enumerated().map { index, raw in
            let text = raw
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let topicID = captureFirst(pattern: "href=\\\"/t/([0-9]+)", in: raw)
            let payload = topicID.map { "/t/\($0)" }

            return V2EXNotification(
                id: index + 1,
                text: text.isEmpty ? "新提醒" : text,
                payload: payload,
                member: nil,
                created: now
            )
        }
    }

    private static func captureFirst(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else { return nil }
        return ns.substring(with: match.range(at: 1))
    }

    private static func captureBlocks(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return ns.substring(with: match.range(at: 1))
        }
    }
}
