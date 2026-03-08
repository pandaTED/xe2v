import SwiftUI

struct NodeDetailView: View {
    @Bindable var env: AppEnvironment
    let node: V2EXNode
    @Binding var selectedTopic: V2EXTopic?

    @State private var topics: [V2EXTopic] = []
    @State private var state: LoadState = .idle
    @State private var page = 1
    @State private var hasMore = true
    @State private var loadingMore = false
    @State private var selectedUsername: String?

    var body: some View {
        Group {
            if case .loaded = state {
                List {
                    ForEach(topics) { topic in
                        TopicRowView(topic: topic,
                                     isRead: env.readHistory.isRead(topic.id),
                                     fontScale: env.settings.fontScale,
                                     onTapUser: { selectedUsername = topic.member.username })
                            .onTapGesture {
                                env.readHistory.markRead(topicID: topic.id)
                                selectedTopic = topic
                            }
                            .onAppear {
                                loadMoreIfNeeded(topic)
                            }
                    }

                    if hasMore, let last = topics.last {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .onAppear {
                            loadMoreIfNeeded(last)
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            } else {
                StateView(state: state) {
                    Task { await load(reset: true) }
                }
            }
        }
        .navigationTitle(node.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    env.favorites.toggle(node: node)
                } label: {
                    Image(systemName: env.favorites.contains(node.name) ? "star.fill" : "star")
                        .foregroundStyle(env.favorites.contains(node.name) ? .yellow : .primary)
                }
            }
        }
        .task {
            if state == .idle {
                await load(reset: true)
            }
        }
        .refreshable {
            await load(reset: true)
        }
        .sheet(item: Binding(
            get: { selectedUsername.map(NodeUserItem.init) },
            set: { selectedUsername = $0?.value }
        )) { item in
            NavigationStack {
                MemberProfileView(env: env, username: item.value)
            }
        }
    }

    private func loadMoreIfNeeded(_ topic: V2EXTopic) {
        guard hasMore else { return }
        guard let last = topics.last, last.id == topic.id else { return }
        guard !loadingMore else { return }
        loadingMore = true
        Task {
            await load(reset: false)
            loadingMore = false
        }
    }

    private func load(reset: Bool) async {
        if reset {
            state = .loading
            page = 1
            hasMore = true
        }
        DebugLog.info("node detail load start node=\(node.name) page=\(page) reset=\(reset)", category: "NodeDetail")
        do {
            let list = try await env.repository.topics(nodeName: node.name, page: page, pageSize: 20)
            if reset {
                topics = list
            } else {
                let existing = Set(topics.map(\.id))
                let deduped = list.filter { !existing.contains($0.id) }
                topics.append(contentsOf: deduped)
                if deduped.isEmpty {
                    hasMore = false
                }
            }

            if list.isEmpty {
                hasMore = false
            }

            state = topics.isEmpty ? .empty(message: "该节点暂无主题") : .loaded
            if hasMore {
                page += 1
            }
            DebugLog.info("node detail load success node=\(node.name) total=\(topics.count) nextPage=\(page) hasMore=\(hasMore)", category: "NodeDetail")
        } catch is CancellationError {
            DebugLog.info("node detail load cancelled node=\(node.name)", category: "NodeDetail")
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
            DebugLog.info("node detail load failed node=\(node.name) msg=\(msg)", category: "NodeDetail")
        }
    }
}

private struct NodeUserItem: Identifiable {
    let value: String
    var id: String { value }
}
