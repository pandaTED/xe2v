import Foundation

actor DraftStore {
    struct ComposeDraft: Codable, Hashable {
        let nodeName: String
        let title: String
        let content: String
        let updatedAt: Date
    }

    struct ReplyDraft: Codable, Hashable {
        let topicID: Int
        let content: String
        let quoteFloor: Int?
        let updatedAt: Date
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let compose = "draft.compose"
        static let reply = "draft.reply"
    }

    func saveCompose(_ draft: ComposeDraft) {
        if let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: Keys.compose)
        }
    }

    func loadCompose() -> ComposeDraft? {
        guard let data = defaults.data(forKey: Keys.compose) else { return nil }
        return try? JSONDecoder().decode(ComposeDraft.self, from: data)
    }

    func clearCompose() {
        defaults.removeObject(forKey: Keys.compose)
    }

    func saveReply(_ draft: ReplyDraft) {
        let key = "\(Keys.reply).\(draft.topicID)"
        if let data = try? JSONEncoder().encode(draft) {
            defaults.set(data, forKey: key)
        }
    }

    func loadReply(topicID: Int) -> ReplyDraft? {
        let key = "\(Keys.reply).\(topicID)"
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReplyDraft.self, from: data)
    }

    func clearReply(topicID: Int) {
        defaults.removeObject(forKey: "\(Keys.reply).\(topicID)")
    }
}
