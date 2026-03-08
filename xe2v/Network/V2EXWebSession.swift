import Foundation
import Combine

@MainActor
final class V2EXWebSession: ObservableObject, V2EXWebSessionProtocol {
    @Published private(set) var sessionState: SessionState = .unauthenticated

    private let cookieStore = CookieStore()
    private let keychain = KeychainStore()
    private let session: URLSession
    private var writeInFlightKey: Set<String> = []

    private let baseURL = URL(string: "https://www.v2ex.com")!

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func restoreSessionIfPossible() async {
        do {
            let cookies = try cookieStore.restore()
            cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
            DebugLog.info("restore session cookies=\(cookies.count)", category: "WebSession")

            if cookies.contains(where: { $0.name.lowercased().contains("a2") || $0.name.lowercased().contains("v2ex") }) {
                let username = try? keychain.read(service: "com.cleanv2ex.auth", account: "username")
                    .flatMap { String(data: $0, encoding: .utf8) }
                sessionState = .fullAccess(username: username ?? "已登录用户")
                DebugLog.info("restore session success username=\(username ?? "已登录用户")", category: "WebSession")
            } else {
                sessionState = .unauthenticated
                DebugLog.info("restore session unauthenticated", category: "WebSession")
            }
        } catch {
            sessionState = .unauthenticated
            DebugLog.info("restore session failed \(error.localizedDescription)", category: "WebSession")
        }
    }

    func bridgeCookies(_ cookies: [HTTPCookie], username: String?) async throws {
        guard !cookies.isEmpty else { throw AppError.invalidInput("未获取到 Cookie") }
        sessionState = .webAuthenticating
        DebugLog.info("bridge cookies count=\(cookies.count)", category: "WebSession")

        cookies.forEach { HTTPCookieStorage.shared.setCookie($0) }
        try cookieStore.save(cookies: cookies)
        if let username, !username.isEmpty {
            try keychain.save(data: Data(username.utf8), service: "com.cleanv2ex.auth", account: "username")
        }
        sessionState = .fullAccess(username: username ?? "已登录用户")
        DebugLog.info("bridge cookies success username=\(username ?? "已登录用户")", category: "WebSession")
    }

    func logout() async {
        if let cookies = HTTPCookieStorage.shared.cookies {
            cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
        cookieStore.clear()
        keychain.delete(service: "com.cleanv2ex.auth", account: "username")
        keychain.delete(service: "com.cleanv2ex.auth", account: "token")
        sessionState = .unauthenticated
    }

    func fetchHomeTopicsViaWeb(feed: TopicFeedType, page: Int) async throws -> [V2EXTopic] {
        let path: String
        switch feed {
        case .hot:
            path = "?tab=hot"
        case .latest:
            path = page <= 1 ? "recent" : "recent?p=\(page)"
        }
        let url = try makeURL(path: path)
        let html = try await fetchHTML(url: url)
        let list = TopicListHTMLParser.parseTopics(html: html)
        DebugLog.info("web home parsed feed=\(feed.rawValue) page=\(page) count=\(list.count)", category: "WebSession")
        return list
    }

    func fetchNodesViaWeb() async throws -> [V2EXNode] {
        let html = try await fetchHTML(url: try makeURL(path: "planes"))
        let list = TopicListHTMLParser.parseNodes(html: html)
        DebugLog.info("web nodes parsed count=\(list.count)", category: "WebSession")
        return list
    }

    func fetchTopicsViaWeb(nodeName: String, page: Int) async throws -> [V2EXTopic] {
        let normalizedPage = max(1, page)
        let path = "go/\(nodeName)?p=\(normalizedPage)"
        let html = try await fetchHTML(url: try makeURL(path: path))
        let list = TopicListHTMLParser.parseTopics(html: html)
        DebugLog.info("web node topics parsed path=\(path) count=\(list.count)", category: "WebSession")
        return list
    }

    func fetchNotificationsViaWeb() async throws -> [V2EXNotification] {
        let url = try makeURL(path: "notifications")
        let html = try await fetchHTML(url: url)

        if html.contains("/signin") && (html.contains("登录") || html.contains("signin")) {
            throw AppError.unauthorized
        }

        let list = NotificationsHTMLParser.parse(html: html)
        DebugLog.info("web notifications parsed count=\(list.count)", category: "WebSession")
        return list
    }

    func fetchReplyFormToken(topicID: Int) async throws -> FormToken {
        let url = try makeURL(path: "t/\(topicID)")
        let html = try await fetchHTML(url: url)
        guard let once = FormParser.parseOnce(from: html) else {
            throw AppError.formTokenNotFound
        }
        let csrf = FormParser.parseCSRF(from: html)
        return FormToken(once: once, csrf: csrf)
    }

    func submitReply(_ request: ReplyRequest) async throws {
        guard case .fullAccess = sessionState else { throw AppError.unsupportedWriteMode }

        let opKey = "reply-\(request.topicID)-\(request.content.hashValue)"
        guard writeInFlightKey.insert(opKey).inserted else {
            throw AppError.publishFailed("请勿重复提交")
        }
        defer { writeInFlightKey.remove(opKey) }

        let token = try await fetchReplyFormToken(topicID: request.topicID)

        var content = request.content
        if let floor = request.quoteFloor {
            content = "#\(floor) 楼\n\n" + content
        }

        var form: [URLQueryItem] = [
            URLQueryItem(name: "content", value: content),
            URLQueryItem(name: "once", value: token.once)
        ]
        if let csrf = token.csrf {
            form.append(URLQueryItem(name: "_csrf", value: csrf))
        }

        var req = URLRequest(url: try makeURL(path: "t/\(request.topicID)"))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = form.percentEncoded()

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("回复失败") }
        guard (200 ... 302).contains(http.statusCode) else { throw AppError.map(statusCode: http.statusCode) }

        let html = String(data: data, encoding: .utf8) ?? ""
        if FormParser.containsReplySuccess(html) {
            return
        }

        if let reason = FormParser.parseFailureReason(html) {
            throw AppError.publishFailed(reason)
        }
        throw AppError.publishFailed("服务器未确认回复成功")
    }

    func fetchComposeFormToken(nodeName: String?) async throws -> FormToken {
        var components = URLComponents(url: try makeURL(path: "new"), resolvingAgainstBaseURL: false)
        if let nodeName, !nodeName.isEmpty {
            components?.queryItems = [URLQueryItem(name: "node", value: nodeName)]
        }
        guard let url = components?.url else { throw AppError.network("URL 无效") }

        let html = try await fetchHTML(url: url)
        guard let once = FormParser.parseOnce(from: html) else {
            throw AppError.formTokenNotFound
        }
        let csrf = FormParser.parseCSRF(from: html)
        return FormToken(once: once, csrf: csrf)
    }

    func submitTopic(_ request: ComposeTopicRequest) async throws {
        guard case .fullAccess = sessionState else { throw AppError.unsupportedWriteMode }
        guard request.title.count >= 2 else { throw AppError.invalidInput("标题过短") }
        guard request.content.count >= 2 else { throw AppError.invalidInput("正文过短") }

        let opKey = "topic-\(request.nodeName)-\(request.title.hashValue)"
        guard writeInFlightKey.insert(opKey).inserted else {
            throw AppError.publishFailed("请勿重复提交")
        }
        defer { writeInFlightKey.remove(opKey) }

        let token = try await fetchComposeFormToken(nodeName: request.nodeName)
        var form: [URLQueryItem] = [
            URLQueryItem(name: "title", value: request.title),
            URLQueryItem(name: "content", value: request.content),
            URLQueryItem(name: "node_name", value: request.nodeName),
            URLQueryItem(name: "once", value: token.once)
        ]
        if let csrf = token.csrf {
            form.append(URLQueryItem(name: "_csrf", value: csrf))
        }

        var req = URLRequest(url: try makeURL(path: "new"))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.httpBody = form.percentEncoded()

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("发帖失败") }
        guard (200 ... 302).contains(http.statusCode) else { throw AppError.map(statusCode: http.statusCode) }

        let html = String(data: data, encoding: .utf8) ?? ""
        if FormParser.containsTopicPublishSuccess(html) {
            return
        }
        if let reason = FormParser.parseFailureReason(html) {
            throw AppError.publishFailed(reason)
        }
        throw AppError.publishFailed("服务器未确认发帖成功")
    }

    private func makeURL(path: String) throws -> URL {
        if path.hasPrefix("?"), var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) {
            components.percentEncodedQuery = String(path.dropFirst())
            if let url = components.url { return url }
        }
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: normalized, relativeTo: baseURL)?.absoluteURL else {
            throw AppError.network("URL 无效")
        }
        return url
    }

    private func fetchHTML(url: URL) async throws -> String {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("text/html", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("无效响应") }
        guard (200 ... 299).contains(http.statusCode) else {
            throw AppError.map(statusCode: http.statusCode)
        }
        guard let html = String(data: data, encoding: .utf8) else { throw AppError.parseFailed }
        return html
    }
}

private extension Array where Element == URLQueryItem {
    func percentEncoded() -> Data? {
        var components = URLComponents()
        components.queryItems = self
        return components.percentEncodedQuery?.data(using: .utf8)
    }
}
