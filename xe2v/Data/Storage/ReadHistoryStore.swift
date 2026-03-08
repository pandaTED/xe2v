import Foundation
import Combine

@MainActor
final class ReadHistoryStore: ObservableObject {
    @Published private(set) var readTopicIDs: Set<Int> = []
    private let defaults = UserDefaults.standard
    private let key = "history.readTopicIDs"

    init() {
        let raw = defaults.array(forKey: key) as? [Int] ?? []
        readTopicIDs = Set(raw)
    }

    func markRead(topicID: Int) {
        readTopicIDs.insert(topicID)
        defaults.set(Array(readTopicIDs), forKey: key)
    }

    func isRead(_ topicID: Int) -> Bool {
        readTopicIDs.contains(topicID)
    }
}
