import Foundation

// 仅本地调试日志，受 settings.debugLog 开关控制
enum DebugLog {
    private static let key = "settings.debugLog"

    static func info(_ message: @autoclosure () -> String,
                     category: String = "App",
                     file: String = #fileID,
                     line: Int = #line) {
#if DEBUG
        guard UserDefaults.standard.bool(forKey: key) else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        let shortFile = file.split(separator: "/").last.map(String.init) ?? file
        print("[DEBUG][\(ts)][\(category)][\(shortFile):\(line)] \(message())")
#endif
    }
}
