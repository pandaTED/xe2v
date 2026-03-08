import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let repository: V2EXRepositoryProtocol

    var profile: V2EXMember?
    var state: LoadState = .idle

    init(repository: V2EXRepositoryProtocol) {
        self.repository = repository
    }

    func loadProfile(username: String?) async {
        guard let username, !username.isEmpty else {
            profile = nil
            state = .empty(message: "登录成功后可查看公开资料")
            return
        }
        state = .loading
        do {
            profile = try await repository.profile(username: username)
            state = .loaded
        } catch {
            let msg = (error as? AppError)?.localizedDescription ?? error.localizedDescription
            state = .failed(message: msg)
        }
    }
}
