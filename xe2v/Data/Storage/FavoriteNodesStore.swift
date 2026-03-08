import Foundation
import Observation

@MainActor
@Observable
final class FavoriteNodesStore {
    struct FavoriteNode: Codable, Hashable, Identifiable {
        var id: String { name }
        let name: String
        let title: String
    }

    private let defaults = UserDefaults.standard
    private let key = "favorites.nodes"

    var nodes: [FavoriteNode] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(nodes) {
                defaults.set(data, forKey: key)
            }
        }
    }

    init() {
        if let data = defaults.data(forKey: key),
           let value = try? JSONDecoder().decode([FavoriteNode].self, from: data) {
            nodes = value
        }
    }

    func contains(_ nodeName: String) -> Bool {
        nodes.contains { $0.name == nodeName }
    }

    func toggle(node: V2EXNode) {
        if contains(node.name) {
            nodes.removeAll { $0.name == node.name }
        } else {
            nodes.insert(.init(name: node.name, title: node.title), at: 0)
        }
    }

    func update(from allNodes: [V2EXNode]) {
        nodes = nodes.map { old in
            if let latest = allNodes.first(where: { $0.name == old.name }) {
                return .init(name: latest.name, title: latest.title)
            }
            return old
        }
    }
}
