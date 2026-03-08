import Foundation
import Observation

@MainActor
@Observable
final class ComposeTopicViewModel {
    private let repository: V2EXRepositoryProtocol
    private let draftStore: DraftStore

    var nodeName = ""
    var title = ""
    var content = ""
    var posting = false
    var nodes: [V2EXNode] = []
    var state: LoadState = .idle

    init(repository: V2EXRepositoryProtocol, draftStore: DraftStore) {
        self.repository = repository
        self.draftStore = draftStore
    }

    func loadDraft() {
        Task {
            if let draft = await draftStore.loadCompose() {
                nodeName = draft.nodeName
                title = draft.title
                content = draft.content
            }
        }
    }

    func autoSaveDraft() {
        Task {
            await draftStore.saveCompose(.init(nodeName: nodeName,
                                              title: title,
                                              content: content,
                                              updatedAt: Date()))
        }
    }

    func loadNodes() async {
        state = .loading
        do {
            nodes = try await repository.nodes()
            state = .loaded
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
        }
    }

    func submit() async throws {
        guard !posting else { return }
        guard !nodeName.isEmpty else { throw AppError.invalidInput("请选择节点") }
        guard title.count >= 2 else { throw AppError.invalidInput("标题至少 2 个字符") }
        guard content.count >= 2 else { throw AppError.invalidInput("正文至少 2 个字符") }

        posting = true
        defer { posting = false }

        let request = ComposeTopicRequest(nodeName: nodeName, title: title, content: content)
        try await repository.submitTopic(request)
        await draftStore.clearCompose()
    }
}
