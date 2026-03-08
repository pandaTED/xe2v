import Foundation

enum AppError: LocalizedError, Equatable {
    case network(String)
    case unauthorized
    case sessionExpired
    case formTokenNotFound
    case rateLimited
    case forbidden
    case publishFailed(String)
    case parseFailed
    case invalidInput(String)
    case unsupportedWriteMode
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let msg):
            return "网络异常：\(msg)"
        case .unauthorized:
            return "登录已失效，请重新登录"
        case .sessionExpired:
            return "会话过期，请重新完成网页登录"
        case .formTokenNotFound:
            return "页面参数抓取失败，请稍后重试"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .forbidden:
            return "权限不足，当前账号无法执行该操作"
        case .publishFailed(let reason):
            return "发布失败：\(reason)"
        case .parseFailed:
            return "数据解析失败"
        case .invalidInput(let reason):
            return "输入不合法：\(reason)"
        case .unsupportedWriteMode:
            return "请先完成网页登录后再发帖/回复"
        case .unknown:
            return "发生未知错误，请稍后重试"
        }
    }

    static func map(statusCode: Int) -> AppError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 429:
            return .rateLimited
        default:
            return .network("HTTP \(statusCode)")
        }
    }
}
