import Foundation

actor MemoryResponseCache {
    private var store: [String: (expire: Date, data: Data)] = [:]

    func get(_ key: String) -> Data? {
        guard let item = store[key] else { return nil }
        if item.expire < Date() {
            store.removeValue(forKey: key)
            return nil
        }
        return item.data
    }

    func set(_ key: String, data: Data, ttl: TimeInterval) {
        store[key] = (Date().addingTimeInterval(ttl), data)
    }
}

struct HTTPClient: Sendable {
    let session: URLSession
    let limiter: RateLimiter
    let cache: MemoryResponseCache

    init(configuration: URLSessionConfiguration = .default) {
        let conf = configuration
        conf.waitsForConnectivity = true
        conf.timeoutIntervalForRequest = 15
        conf.timeoutIntervalForResource = 30
        conf.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024,
                                 diskCapacity: 300 * 1024 * 1024,
                                 diskPath: "v2ex.urlcache")
        self.session = URLSession(configuration: conf)
        self.limiter = RateLimiter()
        self.cache = MemoryResponseCache()
    }

    func request<T: Decodable>(
        _ request: URLRequest,
        decode: T.Type,
        throttleKey: String,
        minInterval: TimeInterval = 0.35,
        cacheTTL: TimeInterval = 0
    ) async throws -> T {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "nil"
        DebugLog.info("start \(method) \(url), key=\(throttleKey), ttl=\(cacheTTL)", category: "HTTP")

        if minInterval > 0 {
            let allowed = await limiter.allow(key: throttleKey, minInterval: minInterval)
            if !allowed {
                DebugLog.info("blocked by limiter key=\(throttleKey)", category: "HTTP")
                throw AppError.rateLimited
            }
        }

        let cacheKey = "\(request.httpMethod ?? "GET")::\(request.url?.absoluteString ?? "")"
        if cacheTTL > 0, let cached = await cache.get(cacheKey) {
            DebugLog.info("cache hit \(url)", category: "HTTP")
            return try decodeData(cached, as: decode)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("无效响应") }
        guard (200 ... 299).contains(http.statusCode) else {
            DebugLog.info("http status=\(http.statusCode) \(url)", category: "HTTP")
            throw AppError.map(statusCode: http.statusCode)
        }
        DebugLog.info("success status=\(http.statusCode) bytes=\(data.count) \(url)", category: "HTTP")

        if cacheTTL > 0 {
            await cache.set(cacheKey, data: data, ttl: cacheTTL)
        }

        return try decodeData(data, as: decode)
    }

    func requestData(
        _ request: URLRequest,
        throttleKey: String,
        minInterval: TimeInterval = 0.3
    ) async throws -> (Data, HTTPURLResponse) {
        let allowed = await limiter.allow(key: throttleKey, minInterval: minInterval)
        if !allowed {
            DebugLog.info("blocked raw request key=\(throttleKey)", category: "HTTP")
            throw AppError.rateLimited
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("无效响应") }
        guard (200 ... 299).contains(http.statusCode) else {
            DebugLog.info("raw status=\(http.statusCode) \(request.url?.absoluteString ?? "nil")", category: "HTTP")
            throw AppError.map(statusCode: http.statusCode)
        }
        DebugLog.info("raw success status=\(http.statusCode) bytes=\(data.count) \(request.url?.absoluteString ?? "nil")", category: "HTTP")
        return (data, http)
    }

    private func decodeData<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.parseFailed
        }
    }
}
