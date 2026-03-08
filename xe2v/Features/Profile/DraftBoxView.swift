import SwiftUI

struct DraftBoxView: View {
    @Bindable var env: AppEnvironment

    @State private var composeDraft: DraftStore.ComposeDraft?

    var body: some View {
        List {
            Section("发帖草稿") {
                if let composeDraft {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(composeDraft.title.isEmpty ? "(无标题)" : composeDraft.title)
                            .font(.headline)
                        Text("节点：\(composeDraft.nodeName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(composeDraft.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("暂无发帖草稿")
                        .foregroundStyle(.secondary)
                }
            }

            Section("回复草稿") {
                Text("回复草稿会在进入对应主题回复页时自动恢复")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("草稿箱")
        .task {
            composeDraft = await env.drafts.loadCompose()
        }
    }
}
