import Foundation

// 登录状态机：清晰描述模式切换，便于后续扩展审核策略
struct LoginStateMachine {
    enum Event {
        case restoreFullAccess(username: String)
        case startWebAuth
        case webAuthSucceeded(username: String)
        case webAuthFailed(message: String)
        case sessionExpired
        case logout
    }

    static func transition(from state: SessionState, event: Event) -> SessionState {
        switch event {
        case .restoreFullAccess(let username), .webAuthSucceeded(let username):
            return .fullAccess(username: username)
        case .startWebAuth:
            return .webAuthenticating
        case .webAuthFailed(let message):
            return .failed(message: message)
        case .sessionExpired:
            return .expired
        case .logout:
            return .unauthenticated
        }
    }
}
