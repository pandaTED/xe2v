import SwiftUI
import UIKit

struct PostBodyView: View {
    let markdownOrPlain: String
    let rawHTML: String?

    @State private var previewImageURL: URL?

    init(markdownOrPlain: String, rawHTML: String? = nil) {
        self.markdownOrPlain = markdownOrPlain
        self.rawHTML = rawHTML
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(textBlocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let text):
                    SelectableTextView(attributedText: makeNSAttributed(text, style: .body))
                        .frame(maxWidth: .infinity, alignment: .leading)

                case .quote(let text):
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.secondary.opacity(0.45))
                            .frame(width: 3)

                        SelectableTextView(attributedText: makeNSAttributed(text, style: .quote))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }

            let imageURLs = collectImageURLs()
            if !imageURLs.isEmpty {
                VStack(spacing: 10) {
                    ForEach(imageURLs, id: \.absoluteString) { url in
                        Button {
                            previewImageURL = url
                        } label: {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.quaternary)
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                case .failure:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.quaternary)
                                        Label("图片加载失败", systemImage: "photo")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.secondary.opacity(0.15))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .sheet(isPresented: Binding(
            get: { previewImageURL != nil },
            set: { if !$0 { previewImageURL = nil } }
        )) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    if let url = previewImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                            case .failure:
                                Text("图片加载失败")
                                    .foregroundStyle(.white)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("关闭") { previewImageURL = nil }
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var textBlocks: [TextBlock] {
        parseTextBlocks(markdownOrPlain)
    }

    private func parseTextBlocks(_ text: String) -> [TextBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [TextBlock] = []
        var paragraphBuffer: [String] = []
        var quoteBuffer: [String] = []

        func flushParagraph() {
            let joined = paragraphBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { blocks.append(.paragraph(joined)) }
            paragraphBuffer.removeAll()
        }

        func flushQuote() {
            let joined = quoteBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { blocks.append(.quote(joined)) }
            quoteBuffer.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(">") {
                flushParagraph()
                let quoteLine = trimmed.replacingOccurrences(of: "^>+\\s?", with: "", options: .regularExpression)
                quoteBuffer.append(quoteLine)
            } else {
                flushQuote()
                paragraphBuffer.append(line)
            }
        }

        flushQuote()
        flushParagraph()

        if blocks.isEmpty {
            let fallback = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !fallback.isEmpty { return [.paragraph(fallback)] }
        }
        return blocks
    }

    private func makeAttributed(_ text: String) -> AttributedString {
        if let parsed = try? AttributedString(markdown: text) {
            return highlightMentions(in: parsed)
        }
        return highlightMentions(in: AttributedString(text))
    }

    private func makeNSAttributed(_ text: String, style: TextStyle) -> NSAttributedString {
        let attr = makeAttributed(text)
        let ns = NSMutableAttributedString(attributedString: NSAttributedString(attr))

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping

        switch style {
        case .body:
            paragraph.lineSpacing = 7
            paragraph.paragraphSpacing = 14
        case .quote:
            paragraph.lineSpacing = 5
            paragraph.paragraphSpacing = 10
        }

        ns.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: ns.length))

        let fallbackFont = UIFont.preferredFont(forTextStyle: style == .body ? .body : .callout)
        ns.enumerateAttribute(.font, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
            if value == nil {
                ns.addAttribute(.font, value: fallbackFont, range: range)
            }
        }

        if style == .quote {
            ns.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: NSRange(location: 0, length: ns.length))
        }

        return ns
    }

    private func highlightMentions(in attributed: AttributedString) -> AttributedString {
        var value = attributed
        let plain = String(value.characters)
        guard let regex = try? NSRegularExpression(pattern: "@([A-Za-z0-9_\\-]+)") else { return value }
        let ns = plain as NSString
        let matches = regex.matches(in: plain, range: NSRange(location: 0, length: ns.length))

        for match in matches.reversed() {
            guard let range = Range(match.range, in: plain),
                  let attrRange = Range(range, in: value) else { continue }
            value[attrRange].foregroundColor = .accentColor
            value[attrRange].font = .body.bold()
        }
        return value
    }

    private func collectImageURLs() -> [URL] {
        let fromText = detectURLs(markdownOrPlain)
            .compactMap { ImageURLNormalizer.normalizedURL(from: $0.absoluteString) }
            .filter(\.isLikelyImageURL)
        let fromHTML = detectImageURLFromHTML(rawHTML)
        let merged = (fromText + fromHTML)
        var seen = Set<String>()
        return merged.filter { seen.insert($0.absoluteString).inserted }
    }

    private func detectURLs(_ text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let ns = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { $0.url }
    }

    private func detectImageURLFromHTML(_ html: String?) -> [URL] {
        guard let html, !html.isEmpty else { return [] }
        guard let regex = try? NSRegularExpression(pattern: "<img[^>]+src=\\\"([^\\\"]+)\\\"", options: [.caseInsensitive]) else { return [] }
        let ns = html as NSString
        let range = NSRange(location: 0, length: ns.length)
        return regex.matches(in: html, range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return ImageURLNormalizer.normalizedURL(from: ns.substring(with: match.range(at: 1)))
        }
    }
}

private enum TextBlock {
    case paragraph(String)
    case quote(String)
}

private enum TextStyle {
    case body
    case quote
}
