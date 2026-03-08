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
    @State private var paginationErrorMessage: String?
    @State private var duplicatePageCount = 0
    @State private var selectedUsername: String?
    @State private var bottomVisible = false

    var body: some View {
        Group {
            if case .loaded = state {
                List {
                    ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                        TopicRowView(topic: topic,
                                     isRead: env.readHistory.isRead(topic.id),
                                     fontScale: env.settings.fontScale,
                                     onTapUser: { selectedUsername = topic.member.username })
                            .onTapGesture {
                                env.readHistory.markRead(topicID: topic.id)
                                selectedTopic = topic
                            }
                            .onAppear {
                                loadMoreIfNeeded(index: index)
                            }
                    }

                    if loadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else if let message = paginationErrorMessage {
                        VStack(spacing: 8) {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("点击重试加载更多") {
                                Task { await retryLoadMore() }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                    } else if hasMore, !topics.isEmpty {
                        Color.clear
                            .frame(height: 1)
                            .id("node-bottom-\(node.name)-\(topics.count)-\(page)")
                            .onAppear {
                                bottomVisible = true
                                loadMoreIfNeeded(index: max(topics.count - 1, 0))
                            }
                            .onDisappear {
                                bottomVisible = false
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
        .onChange(of: loadingMore) { oldValue, newValue in
            guard oldValue, !newValue else { return }
            guard bottomVisible, hasMore else { return }
            loadMoreIfNeeded(index: max(topics.count - 1, 0))
        }
    }

    private func loadMoreIfNeeded(index: Int) {
        guard hasMore else { return }
        guard !loadingMore else { return }
        guard !topics.isEmpty else { return }
        let threshold = max(topics.count - 4, 0)
        guard index >= threshold else { return }
        DebugLog.info("node detail trigger loadMore node=\(node.name) index=\(index) count=\(topics.count) page=\(page)", category: "NodeDetail")
        loadingMore = true
        Task {
            await load(reset: false)
            loadingMore = false
        }
    }

    private func retryLoadMore() async {
        guard hasMore else { return }
        guard !loadingMore else { return }
        loadingMore = true
        await load(reset: false)
        loadingMore = false
    }

    private func load(reset: Bool) async {
        if reset {
            if topics.isEmpty {
                state = .loading
            }
            page = 1
            hasMore = true
            paginationErrorMessage = nil
            duplicatePageCount = 0
        }
        DebugLog.info("node detail load start node=\(node.name) page=\(page) reset=\(reset)", category: "NodeDetail")
        do {
            let list = uniqueTopics(try await env.repository.topics(nodeName: node.name, page: page, pageSize: 20))
            if reset {
                topics = list
                hasMore = !topics.isEmpty
                if hasMore { page = 2 }
            } else {
                let existing = Set(topics.map(\.id))
                let deduped = list.filter { !existing.contains($0.id) }
                topics.append(contentsOf: deduped)
                paginationErrorMessage = nil

                if list.isEmpty {
                    hasMore = false
                } else if deduped.isEmpty {
                    duplicatePageCount += 1
                    page += 1
                    hasMore = duplicatePageCount < 3
                    DebugLog.info("node detail duplicate page count=\(duplicatePageCount) keepPaging=\(hasMore)", category: "NodeDetail")
                } else {
                    duplicatePageCount = 0
                    page += 1
                }
            }

            state = topics.isEmpty ? .empty(message: "该节点暂无主题") : .loaded
            DebugLog.info("node detail load success node=\(node.name) total=\(topics.count) nextPage=\(page) hasMore=\(hasMore)", category: "NodeDetail")
        } catch is CancellationError {
            DebugLog.info("node detail load cancelled node=\(node.name)", category: "NodeDetail")
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            if reset {
                state = .failed(message: msg)
            } else {
                paginationErrorMessage = msg
                state = topics.isEmpty ? .failed(message: msg) : .loaded
            }
            DebugLog.info("node detail load failed node=\(node.name) msg=\(msg)", category: "NodeDetail")
        }
    }

    private func uniqueTopics(_ list: [V2EXTopic]) -> [V2EXTopic] {
        var seen: Set<Int> = []
        var result: [V2EXTopic] = []
        result.reserveCapacity(list.count)
        for item in list where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}

private struct NodeUserItem: Identifiable {
    let value: String
    var id: String { value }
}
