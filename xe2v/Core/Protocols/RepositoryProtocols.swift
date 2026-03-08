import Foundation

protocol V2EXReadAPIProtocol {
    func fetchHotTopics() async throws -> [V2EXTopic]
    func fetchLatestTopics(page: Int, pageSize: Int) async throws -> [V2EXTopic]
    func fetchTopic(id: Int) async throws -> V2EXTopic
    func fetchReplies(topicID: Int, page: Int, pageSize: Int) async throws -> [V2EXReply]
    func fetchNodes() async throws -> [V2EXNode]
    func fetchTopics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic]
    func fetchNotifications() async throws -> [V2EXNotification]
    func fetchProfile(username: String?) async throws -> V2EXMember
}

@MainActor
protocol V2EXWebSessionProtocol: AnyObject {
    var sessionState: SessionState { get }
    func restoreSessionIfPossible() async
    func bridgeCookies(_ cookies: [HTTPCookie], username: String?) async throws
    func logout() async
    func fetchNotificationsViaWeb() async throws -> [V2EXNotification]
    func fetchReplyFormToken(topicID: Int) async throws -> FormToken
    func submitReply(_ request: ReplyRequest) async throws
    func fetchComposeFormToken(nodeName: String?) async throws -> FormToken
    func submitTopic(_ request: ComposeTopicRequest) async throws
}

@MainActor
protocol V2EXRepositoryProtocol {
    func refreshHome(feed: TopicFeedType, page: Int, pageSize: Int) async throws -> [V2EXTopic]
    func topicDetail(id: Int, replyPage: Int, replyPageSize: Int) async throws -> TopicDetailBundle
    func nodes() async throws -> [V2EXNode]
    func topics(nodeName: String, page: Int, pageSize: Int) async throws -> [V2EXTopic]
    func notifications() async throws -> [V2EXNotification]
    func profile(username: String?) async throws -> V2EXMember
    func submitReply(_ request: ReplyRequest) async throws
    func submitTopic(_ request: ComposeTopicRequest) async throws
}
