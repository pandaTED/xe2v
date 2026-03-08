import SwiftUI

struct PostBodyView: View {
    let markdownOrPlain: String
    let rawHTML: String?

    @State private var previewImageURL: URL?

    init(markdownOrPlain: String, rawHTML: String? = nil) {
        self.markdownOrPlain = markdownOrPlain
        self.rawHTML = rawHTML
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(makeAttributed(markdownOrPlain))
                .font(.body)
                .textSelection(.enabled)

            let imageURLs = collectImageURLs()
            if !imageURLs.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(imageURLs, id: \.absoluteString) { url in
                        Button {
                            previewImageURL = url
                        } label: {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quaternary)
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.quaternary)
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(height: 90)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
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

    private func makeAttributed(_ text: String) -> AttributedString {
        if let parsed = try? AttributedString(markdown: text) {
            return highlightMentions(in: parsed)
        }
        return highlightMentions(in: AttributedString(text))
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
        let fromText = detectURLs(markdownOrPlain).filter(\.isImageURL)
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
            return URL(string: ns.substring(with: match.range(at: 1)))
        }
    }
}

private extension URL {
    var isImageURL: Bool {
        let ext = pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(ext)
    }
}
