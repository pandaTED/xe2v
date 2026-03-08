import Foundation

@MainActor
final class V2EXRepository: V2EXRepositoryProtocol {
    private let readAPI: V2EXReadAPIProtocol
    private let webSession: V2EXWebSessionProtocol

    init(readAPI: V2EXReadAPIProtocol, webSession: V2EXWebSessionProtocol) {
        self.readAPI = readAPI
        self.webSession = webSession
    }

    func refreshHome(feed: TopicFeedType, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        switch feed {
        case .hot:
            return try await readAPI.fetchHotTopics()
        case .latest:
            return try await readAPI.fetchLatestTopics(page: page, pageSize: pageSize)
        }
    }

    func topicDetail(id: Int, replyPage: Int, replyPageSize: Int) async throws -> TopicDetailBundle {
        async let topic = readAPI.fetchTopic(id: id)
        async let replies = readAPI.fetchReplies(topicID: id, page: replyPage, pageSize: replyPageSize)
        return try await TopicDetailBundle(topic: topic, replies: replies)
    }

    func nodes() async throws -> [V2EXNode] {
        try await readAPI.fetchNodes()
    }

    func topics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        try await readAPI.fetchTopics(nodeName: nodeName, page: page, pageSize: pageSize)
    }

    func notifications() async throws -> [V2EXNotification] {
        do {
            return try await readAPI.fetchNotifications()
        } catch {
            if case .fullAccess = webSession.sessionState {
                return try await webSession.fetchNotificationsViaWeb()
            }
            throw error
        }
    }

    func profile(username: String?) async throws -> V2EXMember {
        try await readAPI.fetchProfile(username: username)
    }

    func submitReply(_ request: ReplyRequest) async throws {
        try await webSession.submitReply(request)
    }

    func submitTopic(_ request: ComposeTopicRequest) async throws {
        try await webSession.submitTopic(request)
    }
}
