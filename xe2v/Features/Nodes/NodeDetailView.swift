import SwiftUI

struct NodeDetailView: View {
    @Bindable var env: AppEnvironment
    let node: V2EXNode
    @Binding var selectedTopic: V2EXTopic?

    @State private var topics: [V2EXTopic] = []
    @State private var state: LoadState = .idle
    @State private var page = 1
    @State private var loadingMore = false

    var body: some View {
        Group {
            if case .loaded = state {
                List(topics) { topic in
                    TopicRowView(topic: topic,
                                 isRead: env.readHistory.isRead(topic.id),
                                 fontScale: env.settings.fontScale)
                        .onTapGesture {
                            env.readHistory.markRead(topicID: topic.id)
                            selectedTopic = topic
                        }
                        .onAppear {
                            loadMoreIfNeeded(topic)
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
        .task {
            if state == .idle {
                await load(reset: true)
            }
        }
        .onAppear {
            if state == .idle {
                Task { await load(reset: true) }
            }
        }
        .refreshable {
            await load(reset: true)
        }
    }

    private func loadMoreIfNeeded(_ topic: V2EXTopic) {
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
        }
        do {
            let list = try await env.repository.topics(nodeName: node.name, page: page, pageSize: 20)
            if reset {
                topics = list
            } else {
                topics.append(contentsOf: list)
            }
            state = topics.isEmpty ? .empty(message: "该节点暂无主题") : .loaded
            page += 1
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
        }
    }
}
