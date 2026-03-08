import Foundation
import Observation

@MainActor
@Observable
final class TopicDetailViewModel {
    private let repository: V2EXRepositoryProtocol
    let topicID: Int

    var topic: V2EXTopic?
    var replies: [V2EXReply] = []
    var state: LoadState = .idle
    var replyPage = 1
    var isLoadingMore = false
    var quoteFloor: Int?

    private var loadTask: Task<Void, Never>?

    init(repository: V2EXRepositoryProtocol, topicID: Int) {
        self.repository = repository
        self.topicID = topicID
    }

    func load(reset: Bool) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await fetch(reset: reset)
        }
    }

    func loadMoreIfNeeded(lastVisible reply: V2EXReply) {
        guard let last = replies.last, last.id == reply.id else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        Task { [weak self] in
            guard let self else { return }
            await fetch(reset: false)
            self.isLoadingMore = false
        }
    }

    private func fetch(reset: Bool) async {
        if reset {
            state = .loading
            replyPage = 1
        }
        do {
            let bundle = try await repository.topicDetail(id: topicID, replyPage: replyPage, replyPageSize: 30)
            topic = bundle.topic
            if reset {
                replies = bundle.replies
            } else {
                replies.append(contentsOf: bundle.replies)
            }
            state = .loaded
            replyPage += 1
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
        }
    }
}
