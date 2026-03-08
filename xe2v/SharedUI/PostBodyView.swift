import SwiftUI

struct PostBodyView: View {
    let markdownOrPlain: String
    @State private var previewImageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(makeAttributed(markdownOrPlain))
                .font(.body)
                .textSelection(.enabled)

            let imageURLs = detectURLs(markdownOrPlain).filter(\.isImageURL)
            if !imageURLs.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(imageURLs, id: \.absoluteString) { url in
                        Button {
                            previewImageURL = url
                        } label: {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary)
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

    private func detectURLs(_ text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let ns = text as NSString
        let matches = detector.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { $0.url }
    }
}

private extension URL {
    var isImageURL: Bool {
        let ext = pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(ext)
    }
}
