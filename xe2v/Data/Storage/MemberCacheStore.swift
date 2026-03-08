import Foundation

actor MemberCacheStore {
    private let defaults = UserDefaults.standard
    private let key = "cache.members"
    private var cache: [String: V2EXMember] = [:]

    init() {
        if let data = defaults.data(forKey: key),
           let map = try? JSONDecoder().decode([String: V2EXMember].self, from: data) {
            cache = map
        }
    }

    func member(username: String) -> V2EXMember? {
        cache[username.lowercased()]
    }

    func save(member: V2EXMember) {
        cache[member.username.lowercased()] = member
        persist()
    }

    func save(members: [V2EXMember]) {
        for member in members {
            cache[member.username.lowercased()] = member
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: key)
    }
}
