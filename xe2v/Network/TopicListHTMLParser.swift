import Foundation

struct TopicListHTMLParser {
    static func parseTopics(html: String) -> [V2EXTopic] {
        let pattern = "(?s)<div class=\\\"cell item\\\".*?</div>\\s*</div>"
        let blocks = captureBlocks(pattern: pattern, in: html)
        let now = Int(Date().timeIntervalSince1970)

        return blocks.compactMap { block in
            guard let idString = captureFirst(pattern: "href=\\\"/t/([0-9]+)", in: block),
                  let topicID = Int(idString),
                  let title = captureFirst(pattern: "<span class=\\\"item_title\\\">\\s*<a[^>]*>(.*?)</a>", in: block)?.htmlDecoded else {
                return nil
            }

            let nodeName = captureFirst(pattern: "href=\\\"/go/([^\\\"]+)\\\"", in: block) ?? ""
            let nodeTitle = captureFirst(pattern: "class=\\\"node\\\"[^>]*>(.*?)</a>", in: block)?.htmlDecoded ?? nodeName
            let username = captureFirst(pattern: "href=\\\"/member/([^\\\"]+)\\\"", in: block) ?? ""
            let replies = Int(captureFirst(pattern: "class=\\\"count_livid\\\"[^>]*>([0-9]+)</a>", in: block) ?? "0") ?? 0

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

    private static func captureBlocks(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: text, range: range)
        return matches.map { ns.substring(with: $0.range) }
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
