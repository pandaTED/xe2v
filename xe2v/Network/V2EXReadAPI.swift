import Foundation

struct V2EXReadAPI: V2EXReadAPIProtocol {
    private let baseURL = URL(string: "https://www.v2ex.com")!
    private let client: HTTPClient

    init(client: HTTPClient = HTTPClient()) {
        self.client = client
    }

    private func makeURL(path: String) throws -> URL {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: normalized, relativeTo: baseURL)?.absoluteURL else {
            throw AppError.network("URL 组装失败")
        }
        return url
    }

    private func makeReadRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        var components = URLComponents(url: try makeURL(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else { throw AppError.network("URL 组装失败") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    func fetchHotTopics() async throws -> [V2EXTopic] {
        let req = try makeReadRequest(path: "api/topics/hot.json")
        return try await client.request(req, decode: [V2EXTopic].self, throttleKey: "hot", cacheTTL: 45)
    }

    func fetchLatestTopics(page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        let req = try makeReadRequest(
            path: "api/topics/latest.json",
            queryItems: [
                URLQueryItem(name: "p", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
        return try await client.request(req, decode: [V2EXTopic].self, throttleKey: "latest-\(page)", cacheTTL: 20)
    }

    func fetchTopic(id: Int) async throws -> V2EXTopic {
        let req = try makeReadRequest(path: "api/topics/show.json", queryItems: [URLQueryItem(name: "id", value: "\(id)")])
        let list: [V2EXTopic] = try await client.request(req, decode: [V2EXTopic].self, throttleKey: "topic-\(id)", cacheTTL: 20)
        guard let first = list.first else { throw AppError.parseFailed }
        return first
    }

    func fetchReplies(topicID: Int, page: Int, pageSize: Int) async throws -> [V2EXReply] {
        let req = try makeReadRequest(
            path: "api/replies/show.json",
            queryItems: [
                URLQueryItem(name: "topic_id", value: "\(topicID)"),
                URLQueryItem(name: "p", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
        return try await client.request(req, decode: [V2EXReply].self, throttleKey: "reply-\(topicID)-\(page)", cacheTTL: 15)
    }

    func fetchNodes() async throws -> [V2EXNode] {
        let req = try makeReadRequest(path: "api/nodes/all.json")
        return try await client.request(req, decode: [V2EXNode].self, throttleKey: "nodes", cacheTTL: 900)
    }

    func fetchTopics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        let req = try makeReadRequest(
            path: "api/topics/show.json",
            queryItems: [
                URLQueryItem(name: "node_name", value: nodeName),
                URLQueryItem(name: "p", value: "\(page)"),
                URLQueryItem(name: "page_size", value: "\(pageSize)")
            ]
        )
        return try await client.request(req, decode: [V2EXTopic].self, throttleKey: "node-\(nodeName)-\(page)", cacheTTL: 30)
    }

    func fetchNotifications() async throws -> [V2EXNotification] {
        let req = try makeReadRequest(path: "api/notifications/all.json")
        return try await client.request(req, decode: [V2EXNotification].self, throttleKey: "notify", cacheTTL: 15)
    }

    func fetchProfile(username: String?) async throws -> V2EXMember {
        var query: [URLQueryItem] = []
        if let username, !username.isEmpty {
            query.append(URLQueryItem(name: "username", value: username))
        }
        let req = try makeReadRequest(path: "api/members/show.json", queryItems: query)
        return try await client.request(req, decode: V2EXMember.self, throttleKey: "profile-\(username ?? "me")", cacheTTL: 120)
    }
}
