import Foundation
import Observation

@Observable
final class SettingsStore {
    enum ImagePolicy: String, CaseIterable, Identifiable {
        case auto = "自动"
        case wifiOnly = "仅 Wi-Fi"
        case never = "不加载"

        var id: String { rawValue }
    }

    private let defaults = UserDefaults.standard

    var fontScale: Double {
        didSet { defaults.set(fontScale, forKey: Keys.fontScale) }
    }

    var imagePolicy: ImagePolicy {
        didSet { defaults.set(imagePolicy.rawValue, forKey: Keys.imagePolicy) }
    }

    var enableLocalDebugLog: Bool {
        didSet { defaults.set(enableLocalDebugLog, forKey: Keys.debugLog) }
    }

    private enum Keys {
        static let fontScale = "settings.fontScale"
        static let imagePolicy = "settings.imagePolicy"
        static let debugLog = "settings.debugLog"
    }

    init() {
        let savedScale = defaults.object(forKey: Keys.fontScale) as? Double ?? 1.0
        fontScale = max(0.9, min(savedScale, 1.4))

        let savedPolicy = defaults.string(forKey: Keys.imagePolicy) ?? ImagePolicy.auto.rawValue
        imagePolicy = ImagePolicy(rawValue: savedPolicy) ?? .auto

        enableLocalDebugLog = defaults.bool(forKey: Keys.debugLog)
    }

    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
}
