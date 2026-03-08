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
        do {
            DebugLog.info("home load via API feed=\(feed.rawValue) page=\(page)", category: "Repo")
            switch feed {
            case .hot:
                let list = try await readAPI.fetchHotTopics()
                DebugLog.info("home API result count=\(list.count)", category: "Repo")
                return list
            case .latest:
                let list = try await readAPI.fetchLatestTopics(page: page, pageSize: pageSize)
                DebugLog.info("home API result count=\(list.count)", category: "Repo")
                return list
            }
        } catch {
            if case .fullAccess = webSession.sessionState {
                DebugLog.info("home API failed, fallback WEB feed=\(feed.rawValue) page=\(page), error=\(error.localizedDescription)", category: "Repo")
                let list = try await webSession.fetchHomeTopicsViaWeb(feed: feed, page: page)
                DebugLog.info("home WEB result count=\(list.count)", category: "Repo")
                return list
            }
            DebugLog.info("home load failed no fallback, error=\(error.localizedDescription)", category: "Repo")
            throw error
        }
    }

    func topicDetail(id: Int, replyPage: Int, replyPageSize: Int) async throws -> TopicDetailBundle {
        async let topic = readAPI.fetchTopic(id: id)
        async let replies = readAPI.fetchReplies(topicID: id, page: replyPage, pageSize: replyPageSize)
        return try await TopicDetailBundle(topic: topic, replies: replies)
    }

    func nodes() async throws -> [V2EXNode] {
        do {
            DebugLog.info("nodes load via API", category: "Repo")
            let nodes = try await readAPI.fetchNodes()
            DebugLog.info("nodes API result count=\(nodes.count)", category: "Repo")
            return nodes
        } catch {
            if case .fullAccess = webSession.sessionState {
                DebugLog.info("nodes API failed, fallback WEB, error=\(error.localizedDescription)", category: "Repo")
                let nodes = try await webSession.fetchNodesViaWeb()
                DebugLog.info("nodes WEB result count=\(nodes.count)", category: "Repo")
                return nodes
            }
            DebugLog.info("nodes load failed no fallback, error=\(error.localizedDescription)", category: "Repo")
            throw error
        }
    }

    func topics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        do {
            DebugLog.info("node topics via API node=\(nodeName) page=\(page)", category: "Repo")
            let topics = try await readAPI.fetchTopics(nodeName: nodeName, page: page, pageSize: pageSize)
            DebugLog.info("node topics API result count=\(topics.count)", category: "Repo")
            return topics
        } catch {
            if case .fullAccess = webSession.sessionState {
                DebugLog.info("node topics API failed, fallback WEB node=\(nodeName) page=\(page), error=\(error.localizedDescription)", category: "Repo")
                let topics = try await webSession.fetchTopicsViaWeb(nodeName: nodeName, page: page)
                DebugLog.info("node topics WEB result count=\(topics.count)", category: "Repo")
                return topics
            }
            DebugLog.info("node topics failed no fallback, node=\(nodeName), error=\(error.localizedDescription)", category: "Repo")
            throw error
        }
    }

    func notifications() async throws -> [V2EXNotification] {
        do {
            DebugLog.info("notifications via API", category: "Repo")
            let list = try await readAPI.fetchNotifications()
            DebugLog.info("notifications API result count=\(list.count)", category: "Repo")
            return list
        } catch {
            if case .fullAccess = webSession.sessionState {
                DebugLog.info("notifications API failed, fallback WEB, error=\(error.localizedDescription)", category: "Repo")
                let list = try await webSession.fetchNotificationsViaWeb()
                DebugLog.info("notifications WEB result count=\(list.count)", category: "Repo")
                return list
            }
            DebugLog.info("notifications failed no fallback, error=\(error.localizedDescription)", category: "Repo")
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
