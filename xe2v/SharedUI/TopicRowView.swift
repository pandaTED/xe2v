import SwiftUI

struct TopicRowView: View {
    let topic: V2EXTopic
    let isRead: Bool
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(topic.title)
                    .font(.system(size: 16 * fontScale, weight: isRead ? .regular : .semibold))
                    .foregroundStyle(isRead ? .secondary : .primary)
                    .lineLimit(2)
                Spacer(minLength: 12)
                if topic.replies > 0 {
                    Text("\(topic.replies)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.4), in: Capsule())
                }
            }

            HStack(spacing: 8) {
                Text(topic.node.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(topic.member.username)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(topic.createdAt.relativeCN)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.title)，节点 \(topic.node.title)，回复 \(topic.replies)")
    }
}
