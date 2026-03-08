import SwiftUI

struct NotificationsView: View {
    @Bindable var env: AppEnvironment
    @Binding var selectedTopic: V2EXTopic?

    @State private var vm: NotificationsViewModel

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
                        if let topicID = vm.topicID(from: item.payload) {
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
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.text)
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
