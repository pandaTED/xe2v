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
    var hasMoreReplies = true
    var isLoadingMore = false
    var paginationErrorMessage: String?
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
            if replies.isEmpty && topic == nil {
                state = .loading
            }
            replyPage = 1
            hasMoreReplies = true
            paginationErrorMessage = nil
            await fetch(reset: true)
            isRefreshing = false
            return
        }
        await fetch(reset: false)
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard hasMoreReplies else { return }
        guard !isRefreshing else { return }
        guard !isLoadingMore else { return }
        guard !replies.isEmpty else { return }
        let threshold = max(replies.count - 4, 0)
        guard currentIndex >= threshold else { return }
        isLoadingMore = true
        Task { [weak self] in
            guard let self else { return }
            await load(reset: false)
            self.isLoadingMore = false
        }
    }

    func retryLoadMore() async {
        guard hasMoreReplies else { return }
        guard !isRefreshing else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        await load(reset: false)
        isLoadingMore = false
    }

    private func fetch(reset: Bool) async {
        DebugLog.info("topic detail load start id=\(topicID) page=\(replyPage) reset=\(reset)", category: "TopicVM")
        do {
            let bundle = try await repository.topicDetail(id: topicID, replyPage: replyPage, replyPageSize: 30)
            topic = bundle.topic
            let incoming = uniqueReplies(bundle.replies)
            if reset {
                replies = incoming
                if incoming.isEmpty {
                    hasMoreReplies = false
                } else {
                    replyPage = 2
                }
            } else {
                let existing = Set(replies.map(\.id))
                let deduped = incoming.filter { !existing.contains($0.id) }
                replies.append(contentsOf: deduped)
                paginationErrorMessage = nil
                if incoming.isEmpty || deduped.isEmpty {
                    hasMoreReplies = false
                } else {
                    replyPage += 1
                }
            }
            state = .loaded
            if !hasMoreReplies {
                DebugLog.info("topic detail paging stopped hasMoreReplies=false id=\(topicID)", category: "TopicVM")
            }
            DebugLog.info("topic detail load success id=\(topicID) replies=\(replies.count) nextPage=\(replyPage) hasMore=\(hasMoreReplies)", category: "TopicVM")
        } catch is CancellationError {
            DebugLog.info("topic detail load cancelled id=\(topicID)", category: "TopicVM")
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            if reset {
                state = .failed(message: msg)
            } else {
                paginationErrorMessage = msg
                state = replies.isEmpty ? .failed(message: msg) : .loaded
            }
            DebugLog.info("topic detail load failed id=\(topicID) reset=\(reset) msg=\(msg)", category: "TopicVM")
        }
    }

    private func uniqueReplies(_ list: [V2EXReply]) -> [V2EXReply] {
        var seen: Set<Int> = []
        var result: [V2EXReply] = []
        result.reserveCapacity(list.count)
        for item in list where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
