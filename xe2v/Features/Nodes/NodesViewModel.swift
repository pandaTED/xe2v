import Foundation
import Observation

@MainActor
@Observable
final class NodesViewModel {
    private let repository: V2EXRepositoryProtocol

    var allNodes: [V2EXNode] = []
    var searchText = ""
    var state: LoadState = .idle

    init(repository: V2EXRepositoryProtocol) {
        self.repository = repository
    }

    var filteredNodes: [V2EXNode] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return allNodes }
        return allNodes.filter {
            $0.name.localizedCaseInsensitiveContains(keyword)
                || $0.title.localizedCaseInsensitiveContains(keyword)
        }
    }

    func load() async {
        state = .loading
        DebugLog.info("nodes vm load start", category: "NodesVM")
        do {
            allNodes = try await repository.nodes().sorted(by: { $0.name < $1.name })
            state = allNodes.isEmpty ? .empty(message: "暂无节点") : .loaded
            DebugLog.info("nodes vm load success count=\(allNodes.count)", category: "NodesVM")
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
            DebugLog.info("nodes vm load failed \(msg)", category: "NodesVM")
        }
    }
}
