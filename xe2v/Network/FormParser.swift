import Foundation

struct FormParser {
    static func parseOnce(from html: String) -> String? {
        // 兼容 once= 和隐藏 input 两种常见方式
        if let value = match(pattern: "name=\\\"once\\\"\\s+value=\\\"([^\\\"]+)\\\"", in: html) {
            return value
        }
        return match(pattern: "once=([0-9]+)", in: html)
    }

    static func parseCSRF(from html: String) -> String? {
        match(pattern: "name=\\\"_csrf\\\"\\s+value=\\\"([^\\\"]+)\\\"", in: html)
    }

    static func containsReplySuccess(_ html: String) -> Bool {
        html.contains("topic_buttons") || html.contains("感谢回复") || html.contains("回复成功")
    }

    static func containsTopicPublishSuccess(_ html: String) -> Bool {
        html.contains("/t/") && html.contains("gray")
    }

    static func parseFailureReason(_ html: String) -> String? {
        match(pattern: "<div class=\\\"problem\\\">\\s*<ul>\\s*<li>([^<]+)</li>", in: html)
            ?? match(pattern: "<span class=\\\"fade\\\">([^<]+)</span>", in: html)
    }

    private static func match(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let result = regex.firstMatch(in: text, range: range), result.numberOfRanges > 1 else { return nil }
        return ns.substring(with: result.range(at: 1))
    }
}
