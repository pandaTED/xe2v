import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let settings = SettingsStore()
    let drafts = DraftStore()
    let readHistory = ReadHistoryStore()
    let favorites = FavoriteNodesStore()
    let memberCache = MemberCacheStore()
    let webSession: V2EXWebSession

    let repository: V2EXRepositoryProtocol

    var toastMessage: String?

    init() {
        let webSession = V2EXWebSession()
        self.webSession = webSession
        let readAPI = V2EXReadAPI()
        repository = V2EXRepository(readAPI: readAPI, webSession: webSession, memberCache: memberCache)

        Task {
            await webSession.restoreSessionIfPossible()
        }
    }

    func showError(_ error: Error) {
        if let appError = error as? AppError {
            toastMessage = appError.localizedDescription
        } else {
            toastMessage = error.localizedDescription
        }
    }
}
