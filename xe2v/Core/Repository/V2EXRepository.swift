import Foundation

@MainActor
final class V2EXRepository: V2EXRepositoryProtocol {
    private let readAPI: V2EXReadAPIProtocol
    private let webSession: V2EXWebSessionProtocol
    private let memberCache: MemberCacheStore

    init(readAPI: V2EXReadAPIProtocol, webSession: V2EXWebSessionProtocol, memberCache: MemberCacheStore) {
        self.readAPI = readAPI
        self.webSession = webSession
        self.memberCache = memberCache
    }

    func refreshHome(feed: TopicFeedType, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        if feed == .latest, page > 1 {
            let list = try await webSession.fetchHomeTopicsViaWeb(feed: feed, page: page)
            await memberCache.save(members: list.map(\.member))
            return list
        }

        do {
            DebugLog.info("home load via API feed=\(feed.rawValue) page=\(page)", category: "Repo")
            switch feed {
            case .hot:
                let list = try await readAPI.fetchHotTopics()
                await memberCache.save(members: list.map(\.member))
                DebugLog.info("home API result count=\(list.count)", category: "Repo")
                return list
            case .latest:
                let list = try await readAPI.fetchLatestTopics(page: page, pageSize: pageSize)
                await memberCache.save(members: list.map(\.member))
                DebugLog.info("home API result count=\(list.count)", category: "Repo")
                return list
            }
        } catch {
            DebugLog.info("home API failed, fallback WEB feed=\(feed.rawValue) page=\(page), error=\(error.localizedDescription)", category: "Repo")
            let list = try await webSession.fetchHomeTopicsViaWeb(feed: feed, page: page)
            await memberCache.save(members: list.map(\.member))
            DebugLog.info("home WEB result count=\(list.count)", category: "Repo")
            return list
        }
    }

    func topicDetail(id: Int, replyPage: Int, replyPageSize: Int) async throws -> TopicDetailBundle {
        async let topic = readAPI.fetchTopic(id: id)
        async let replies = readAPI.fetchReplies(topicID: id, page: replyPage, pageSize: replyPageSize)
        let bundle = try await TopicDetailBundle(topic: topic, replies: replies)
        await memberCache.save(member: bundle.topic.member)
        await memberCache.save(members: bundle.replies.map(\.member))
        return bundle
    }

    func nodes() async throws -> [V2EXNode] {
        do {
            DebugLog.info("nodes load via API", category: "Repo")
            let nodes = try await readAPI.fetchNodes()
            DebugLog.info("nodes API result count=\(nodes.count)", category: "Repo")
            if nodes.isEmpty {
                let fallback = try await webSession.fetchNodesViaWeb()
                DebugLog.info("nodes API empty, fallback WEB count=\(fallback.count)", category: "Repo")
                return fallback
            } else {
                return nodes
            }
        } catch {
            DebugLog.info("nodes API failed, fallback WEB, error=\(error.localizedDescription)", category: "Repo")
            let nodes = try await webSession.fetchNodesViaWeb()
            DebugLog.info("nodes WEB result count=\(nodes.count)", category: "Repo")
            return nodes
        }
    }

    func topics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic] {
        // 节点分页统一按网页规则 /go/{node}?p={page}
        do {
            DebugLog.info("node topics via WEB node=\(nodeName) page=\(page)", category: "Repo")
            let topics = try await webSession.fetchTopicsViaWeb(nodeName: nodeName, page: page)
            await memberCache.save(members: topics.map(\.member))
            DebugLog.info("node topics WEB result count=\(topics.count)", category: "Repo")

            if page == 1, topics.isEmpty {
                DebugLog.info("node topics WEB empty on first page, fallback API node=\(nodeName)", category: "Repo")
                let apiTopics = try await readAPI.fetchTopics(nodeName: nodeName, page: page, pageSize: pageSize)
                await memberCache.save(members: apiTopics.map(\.member))
                DebugLog.info("node topics API fallback result count=\(apiTopics.count)", category: "Repo")
                return apiTopics
            }
            return topics
        } catch {
            DebugLog.info("node topics WEB failed, fallback API node=\(nodeName) page=\(page), error=\(error.localizedDescription)", category: "Repo")
            let apiTopics = try await readAPI.fetchTopics(nodeName: nodeName, page: page, pageSize: pageSize)
            await memberCache.save(members: apiTopics.map(\.member))
            DebugLog.info("node topics API fallback result count=\(apiTopics.count)", category: "Repo")
            return apiTopics
        }
    }

    func notifications() async throws -> [V2EXNotification] {
        do {
            DebugLog.info("notifications via API", category: "Repo")
            let list = try await readAPI.fetchNotifications()
            DebugLog.info("notifications API result count=\(list.count)", category: "Repo")
            await memberCache.save(members: list.compactMap(\.member))
            return list
        } catch {
            DebugLog.info("notifications API failed, fallback WEB, error=\(error.localizedDescription)", category: "Repo")
            let list = try await webSession.fetchNotificationsViaWeb()
            await memberCache.save(members: list.compactMap(\.member))
            DebugLog.info("notifications WEB result count=\(list.count)", category: "Repo")
            return list
        }
    }

    func profile(username: String?) async throws -> V2EXMember {
        let member = try await readAPI.fetchProfile(username: username)
        await memberCache.save(member: member)
        return member
    }

    func submitReply(_ request: ReplyRequest) async throws {
        try await webSession.submitReply(request)
    }

    func submitTopic(_ request: ComposeTopicRequest) async throws {
        try await webSession.submitTopic(request)
    }
}
