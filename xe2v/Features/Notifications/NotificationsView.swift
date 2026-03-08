import SwiftUI

struct NotificationsView: View {
    @Bindable var env: AppEnvironment
    @Binding var selectedTopic: V2EXTopic?

    @State private var vm: NotificationsViewModel
    @State private var selectedNotification: V2EXNotification?

    init(env: AppEnvironment, selectedTopic: Binding<V2EXTopic?>) {
        self._env = Bindable(env)
        self._selectedTopic = selectedTopic
        _vm = State(initialValue: NotificationsViewModel(repository: env.repository))
    }

    var body: some View {
        Group {
            if case .loaded = vm.state {
                List(vm.notifications) { item in
                    Button {
                        selectedNotification = item
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(vm.displayText(for: item))
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Text(item.createdAt.relativeCN)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            } else {
                StateView(state: vm.state) {
                    Task { await vm.load() }
                }
            }
        }
        .navigationTitle("通知")
        .sheet(item: $selectedNotification) { item in
            NotificationDetailSheet(item: item, content: vm.displayText(for: item), topicID: vm.topicID(from: item.payload)) { topicID in
                selectedTopic = V2EXTopic(
                    id: topicID,
                    title: "通知跳转",
                    url: nil,
                    content: nil,
                    contentRendered: nil,
                    replies: 0,
                    member: item.member ?? .init(id: 0, username: "", url: nil, website: nil, github: nil, avatarMini: nil, avatarNormal: nil, avatarLarge: nil, tagline: nil, bio: nil),
                    node: .init(id: 0, name: "", title: "", titleAlternative: nil, url: nil, topics: nil, avatarMini: nil, avatarNormal: nil, avatarLarge: nil, header: nil, footer: nil),
                    created: Int(item.createdAt.timeIntervalSince1970),
                    lastModified: nil,
                    lastTouched: nil
                )
            }
        }
        .task {
            if vm.state == .idle {
                await vm.load()
            }
        }
        .onAppear {
            if vm.state == .idle {
                Task { await vm.load() }
            }
        }
        .refreshable {
            await vm.load()
        }
    }
}

private struct NotificationDetailSheet: View {
    let item: V2EXNotification
    let content: String
    let topicID: Int?
    let onOpenTopic: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("内容") {
                    Text(content)
                        .textSelection(.enabled)
                }
                Section("时间") {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                if let topicID {
                    Section {
                        Button("打开关联帖子 #\(topicID)") {
                            onOpenTopic(topicID)
                        }
                    }
                }
                if let payload = item.payload, !payload.isEmpty {
                    Section("原始数据") {
                        Text(payload)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("通知详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
