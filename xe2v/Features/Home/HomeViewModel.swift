import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let repository: V2EXRepositoryProtocol

    var feedType: TopicFeedType = .hot
    var topics: [V2EXTopic] = []
    var state: LoadState = .idle
    var page: Int = 1
    var isLoadingMore = false

    private var loadTask: Task<Void, Never>?

    init(repository: V2EXRepositoryProtocol) {
        self.repository = repository
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await load(reset: true)
        }
    }

    func switchFeed(_ feed: TopicFeedType) {
        guard feed != feedType else { return }
        feedType = feed
        refresh()
    }

    func loadMoreIfNeeded(current topic: V2EXTopic) {
        guard feedType == .latest, let last = topics.last, last.id == topic.id else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        Task { [weak self] in
            guard let self else { return }
            await load(reset: false)
            self.isLoadingMore = false
        }
    }

    private func load(reset: Bool) async {
        if reset {
            state = .loading
            page = 1
        }

        do {
            let list = try await repository.refreshHome(feed: feedType, page: page, pageSize: 20)
            if reset {
                topics = list
            } else {
                topics.append(contentsOf: list)
            }

            if topics.isEmpty {
                state = .empty(message: "暂无主题")
            } else {
                state = .loaded
            }

            if feedType == .latest {
                page += 1
            }
        } catch {
            let message = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: message)
        }
    }
}
