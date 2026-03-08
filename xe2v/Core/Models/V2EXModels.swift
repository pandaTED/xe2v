import Foundation

// MARK: - 通用模型

struct V2EXMember: Codable, Hashable, Identifiable {
    let id: Int
    let username: String
    let url: String?
    let website: String?
    let github: String?
    let avatarMini: String?
    let avatarNormal: String?
    let avatarLarge: String?
    let tagline: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case url
        case website
        case github
        case avatarMini = "avatar_mini"
        case avatarNormal = "avatar_normal"
        case avatarLarge = "avatar_large"
        case tagline
        case bio
    }
}

struct V2EXNode: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let title: String
    let titleAlternative: String?
    let url: String?
    let topics: Int?
    let avatarMini: String?
    let avatarNormal: String?
    let avatarLarge: String?
    let header: String?
    let footer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case titleAlternative = "title_alternative"
        case url
        case topics
        case avatarMini = "avatar_mini"
        case avatarNormal = "avatar_normal"
        case avatarLarge = "avatar_large"
        case header
        case footer
    }
}

struct V2EXTopic: Codable, Hashable, Identifiable {
    let id: Int
    let title: String
    let url: String?
    let content: String?
    let contentRendered: String?
    let replies: Int
    let member: V2EXMember
    let node: V2EXNode
    let created: Int
    let lastModified: Int?
    let lastTouched: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case content
        case contentRendered = "content_rendered"
        case replies
        case member
        case node
        case created
        case lastModified = "last_modified"
        case lastTouched = "last_touched"
    }

    var createdAt: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
}

struct V2EXReply: Codable, Hashable, Identifiable {
    let id: Int
    let thanks: Int?
    let content: String?
    let contentRendered: String?
    let member: V2EXMember
    let created: Int

    enum CodingKeys: String, CodingKey {
        case id
        case thanks
        case content
        case contentRendered = "content_rendered"
        case member
        case created
    }

    var createdAt: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
}

struct V2EXNotification: Codable, Hashable, Identifiable {
    let id: Int
    let text: String
    let payload: String?
    let member: V2EXMember?
    let created: Int

    var createdAt: Date { Date(timeIntervalSince1970: TimeInterval(created)) }
}

struct TopicDetailBundle: Hashable {
    let topic: V2EXTopic
    let replies: [V2EXReply]
}

enum TopicFeedType: String, CaseIterable, Identifiable {
    case hot = "热门"
    case latest = "最新"

    var id: String { rawValue }
}

struct ComposeTopicRequest: Hashable {
    let nodeName: String
    let title: String
    let content: String
}

struct ReplyRequest: Hashable {
    let topicID: Int
    let content: String
    let quoteFloor: Int?
}
