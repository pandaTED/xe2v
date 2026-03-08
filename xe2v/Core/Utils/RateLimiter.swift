import Foundation

actor RateLimiter {
    private var records: [String: Date] = [:]

    func allow(key: String, minInterval: TimeInterval) -> Bool {
        let now = Date()
        if let last = records[key], now.timeIntervalSince(last) < minInterval {
            return false
        }
        records[key] = now
        return true
    }
}
