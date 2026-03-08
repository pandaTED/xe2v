import Foundation

enum SessionState: Equatable {
    case unauthenticated
    case webAuthenticating
    case fullAccess(username: String)
    case expired
    case failed(message: String)

    var canWrite: Bool {
        if case .fullAccess = self { return true }
        return false
    }
}

struct FormToken: Hashable {
    let once: String
    let csrf: String?
}
