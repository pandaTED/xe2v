import Foundation
import Observation

@MainActor
@Observable
final class NotificationsViewModel {
    private let repository: V2EXRepositoryProtocol

    var notifications: [V2EXNotification] = []
    var state: LoadState = .idle

    init(repository: V2EXRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            notifications = try await repository.notifications()
            state = notifications.isEmpty ? .empty(message: "暂无提醒") : .loaded
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
        }
    }

    func topicID(from payload: String?) -> Int? {
        guard let payload else { return nil }
        let pattern = "/t/([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = payload as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: payload, range: range), match.numberOfRanges > 1 else { return nil }
        return Int(ns.substring(with: match.range(at: 1)))
    }
}
