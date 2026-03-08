import Foundation

struct TopicListHTMLParser {
    static func parseTopics(html: String) -> [V2EXTopic] {
        let pattern = "(?s)<span class=\\\"item_title\\\">\\s*<a href=\\\"/t/([0-9]+)(?:#[^\\\"]+)?\\\">(.*?)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }

        let ns = html as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: html, range: range)
        let now = Int(Date().timeIntervalSince1970)

        return matches.compactMap { match in
            guard match.numberOfRanges > 2 else { return nil }
            let idString = ns.substring(with: match.range(at: 1))
            let titleRaw = ns.substring(with: match.range(at: 2))
            guard let topicID = Int(idString) else { return nil }

            let start = max(0, match.range.location - 280)
            let length = min(ns.length - start, 560)
            let context = ns.substring(with: NSRange(location: start, length: length))

            let title = titleRaw.htmlDecoded
            guard !title.isEmpty else { return nil }

            let nodeName = captureFirst(pattern: "href=\\\"/go/([^\\\"]+)\\\"", in: context) ?? ""
            let nodeTitle = captureFirst(pattern: "class=\\\"node\\\"[^>]*>(.*?)</a>", in: context)?.htmlDecoded ?? nodeName
            let username = captureFirst(pattern: "href=\\\"/member/([^\\\"]+)\\\"", in: context) ?? ""
            let replies = Int(captureFirst(pattern: "class=\\\"count_livid\\\"[^>]*>([0-9]+)</a>", in: context) ?? "0") ?? 0

            return V2EXTopic(
                id: topicID,
                title: title,
                url: "https://www.v2ex.com/t/\(topicID)",
                content: nil,
                contentRendered: nil,
                replies: replies,
                member: .init(id: 0, username: username, url: nil, website: nil, github: nil, avatarMini: nil, avatarNormal: nil, avatarLarge: nil, tagline: nil, bio: nil),
                node: .init(id: 0, name: nodeName, title: nodeTitle.isEmpty ? nodeName : nodeTitle, titleAlternative: nil, url: nil, topics: nil, avatarMini: nil, avatarNormal: nil, avatarLarge: nil, header: nil, footer: nil),
                created: now,
                lastModified: nil,
                lastTouched: nil
            )
        }
    }

    static func parseNodes(html: String) -> [V2EXNode] {
        let pattern = "<a href=\\\"/go/([^\\\"]+)\\\"[^>]*>(.*?)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let ns = html as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: html, range: range)

        var seen: Set<String> = []
        var nodes: [V2EXNode] = []

        for match in matches {
            guard match.numberOfRanges > 2 else { continue }
            let name = ns.substring(with: match.range(at: 1))
            if seen.contains(name) { continue }
            seen.insert(name)

            let title = ns.substring(with: match.range(at: 2)).htmlDecoded
            nodes.append(
                V2EXNode(
                    id: nodes.count + 1,
                    name: name,
                    title: title,
                    titleAlternative: nil,
                    url: "https://www.v2ex.com/go/\(name)",
                    topics: nil,
                    avatarMini: nil,
                    avatarNormal: nil,
                    avatarLarge: nil,
                    header: nil,
                    footer: nil
                )
            )
        }

        return nodes
    }

    private static func captureFirst(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else { return nil }
        return ns.substring(with: match.range(at: 1))
    }
}

private extension String {
    var htmlDecoded: String {
        self
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
