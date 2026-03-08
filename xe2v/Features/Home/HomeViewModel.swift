import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let repository: V2EXRepositoryProtocol

    var feedType: TopicFeedType = .latest
    var selectedQuickNodeName: String?
    var topics: [V2EXTopic] = []
    var state: LoadState = .idle
    var page: Int = 1
    var hasMore = true
    var isLoadingMore = false
    var paginationErrorMessage: String?
    private var isRefreshing = false

    init(repository: V2EXRepositoryProtocol) {
        self.repository = repository
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await load(reset: true)
    }

    func switchFeed(_ feed: TopicFeedType) {
        guard feed != feedType else { return }
        feedType = feed
        selectedQuickNodeName = nil
        Task { await refresh() }
    }

    func switchQuickNode(_ nodeName: String?) {
        guard selectedQuickNodeName != nodeName else { return }
        selectedQuickNodeName = nodeName
        Task { await refresh() }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard hasMore else { return }
        guard !isRefreshing else { return }
        guard !isLoadingMore else { return }
        guard !topics.isEmpty else { return }
        let threshold = max(topics.count - 4, 0)
        guard currentIndex >= threshold else { return }
        isLoadingMore = true
        Task { [weak self] in
            guard let self else { return }
            await load(reset: false)
            self.isLoadingMore = false
        }
    }

    func retryLoadMore() async {
        guard hasMore else { return }
        guard !isRefreshing else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        await load(reset: false)
        isLoadingMore = false
    }

    private func load(reset: Bool) async {
        if reset {
            state = .loading
            page = 1
            hasMore = true
            paginationErrorMessage = nil
        }
        DebugLog.info("home vm load start feed=\(feedType.rawValue) page=\(page) reset=\(reset)", category: "HomeVM")

        do {
            let list: [V2EXTopic]
            if let node = selectedQuickNodeName {
                list = try await repository.topics(nodeName: node, page: page, pageSize: 20)
            } else {
                list = try await repository.refreshHome(feed: feedType, page: page, pageSize: 20)
            }

            let existing = Set(topics.map(\.id))
            let deduped = list.filter { !existing.contains($0.id) }

            if reset {
                topics = list
            } else {
                topics.append(contentsOf: deduped)
                paginationErrorMessage = nil
            }

            if topics.isEmpty {
                state = .empty(message: "暂无主题")
            } else {
                state = .loaded
            }

            if list.isEmpty || (!reset && deduped.isEmpty) {
                hasMore = false
            } else {
                page += 1
            }
            if !hasMore {
                DebugLog.info("home vm paging stopped hasMore=false", category: "HomeVM")
            }
            DebugLog.info("home vm load success count=\(topics.count) nextPage=\(page)", category: "HomeVM")
        } catch is CancellationError {
            DebugLog.info("home vm load cancelled", category: "HomeVM")
        } catch {
            let message = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            if reset {
                state = .failed(message: message)
            } else {
                paginationErrorMessage = message
                state = topics.isEmpty ? .failed(message: message) : .loaded
            }
            DebugLog.info("home vm load failed reset=\(reset) msg=\(message)", category: "HomeVM")
        }
    }
}
