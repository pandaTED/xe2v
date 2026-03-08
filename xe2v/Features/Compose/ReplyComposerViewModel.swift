import Foundation
import Observation

@MainActor
@Observable
final class ReplyComposerViewModel {
    private let repository: V2EXRepositoryProtocol
    private let draftStore: DraftStore

    let topicID: Int
    var quoteFloor: Int?
    var content = ""
    var posting = false

    init(repository: V2EXRepositoryProtocol, draftStore: DraftStore, topicID: Int, quoteFloor: Int?) {
        self.repository = repository
        self.draftStore = draftStore
        self.topicID = topicID
        self.quoteFloor = quoteFloor
    }

    func loadDraft() {
        Task {
            if let draft = await draftStore.loadReply(topicID: topicID) {
                content = draft.content
                if quoteFloor == nil { quoteFloor = draft.quoteFloor }
            }
        }
    }

    func autoSaveDraft() {
        Task {
            await draftStore.saveReply(.init(topicID: topicID,
                                            content: content,
                                            quoteFloor: quoteFloor,
                                            updatedAt: Date()))
        }
    }

    func submit() async throws {
        guard content.count >= 2 else { throw AppError.invalidInput("回复内容至少 2 个字符") }
        guard !posting else { return }
        posting = true
        defer { posting = false }

        try await repository.submitReply(.init(topicID: topicID, content: content, quoteFloor: quoteFloor))
        await draftStore.clearReply(topicID: topicID)
    }
}
