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
    private var isRefreshing = false

    init(repository: V2EXRepositoryProtocol, topicID: Int) {
        self.repository = repository
        self.topicID = topicID
    }

    func load(reset: Bool) async {
        if reset {
            guard !isRefreshing else { return }
            isRefreshing = true
            await fetch(reset: true)
            isRefreshing = false
            return
        }
        await fetch(reset: false)
    }

    func loadMoreIfNeeded(lastVisible reply: V2EXReply) {
        guard let last = replies.last, last.id == reply.id else { return }
        guard !isRefreshing else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        Task { [weak self] in
            guard let self else { return }
            await load(reset: false)
            self.isLoadingMore = false
        }
    }

    private func fetch(reset: Bool) async {
        if reset {
            state = .loading
            replyPage = 1
        }
        DebugLog.info("topic detail load start id=\(topicID) page=\(replyPage) reset=\(reset)", category: "TopicVM")
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
            DebugLog.info("topic detail load success id=\(topicID) replies=\(replies.count) nextPage=\(replyPage)", category: "TopicVM")
        } catch is CancellationError {
            DebugLog.info("topic detail load cancelled id=\(topicID)", category: "TopicVM")
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
            DebugLog.info("topic detail load failed id=\(topicID) msg=\(msg)", category: "TopicVM")
        }
    }
}
