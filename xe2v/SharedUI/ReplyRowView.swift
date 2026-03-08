import SwiftUI

struct ReplyRowView: View {
    let reply: V2EXReply
    let floor: Int
    let fontScale: Double
    let onTapUser: () -> Void
    let onQuote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                CachedAsyncImage(urlString: reply.member.avatarNormal, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Button(reply.member.username) { onTapUser() }
                        .buttonStyle(.plain)
                        .font(.system(size: 13 * fontScale, weight: .semibold))
                    Text(reply.createdAt.relativeCN)
                        .font(.system(size: 11 * fontScale))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("#\(floor)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PostBodyView(markdownOrPlain: reply.content ?? HTMLContentRenderer.plainText(from: reply.contentRendered),
                         rawHTML: reply.contentRendered)
                .font(.system(size: 15 * fontScale))

            HStack {
                Button("引用") { onQuote() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .id(floor)
    }
}
