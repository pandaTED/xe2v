import Foundation

@MainActor
final class CookieStore {
    private let keychain = KeychainStore()
    private let service = "com.cleanv2ex.cookie"
    private let account = "v2ex.cookie.snapshot"

    struct CodableCookie: Codable {
        let properties: [String: String]

        init?(cookie: HTTPCookie) {
            var props: [String: String] = [:]
            props[HTTPCookiePropertyKey.name.rawValue] = cookie.name
            props[HTTPCookiePropertyKey.value.rawValue] = cookie.value
            props[HTTPCookiePropertyKey.path.rawValue] = cookie.path
            props[HTTPCookiePropertyKey.domain.rawValue] = cookie.domain
            props[HTTPCookiePropertyKey.expires.rawValue] = cookie.expiresDate?.description
            props[HTTPCookiePropertyKey.secure.rawValue] = cookie.isSecure ? "1" : "0"
            props[HTTPCookiePropertyKey.version.rawValue] = "\(cookie.version)"
            self.properties = props
        }

        var cookie: HTTPCookie? {
            var dict: [HTTPCookiePropertyKey: Any] = [:]
            for (key, value) in properties {
                dict[HTTPCookiePropertyKey(rawValue: key)] = value
            }
            return HTTPCookie(properties: dict)
        }
    }

    func save(cookies: [HTTPCookie]) throws {
        let codable = cookies.compactMap(CodableCookie.init(cookie:))
        let data = try JSONEncoder().encode(codable)
        try keychain.save(data: data, service: service, account: account)
    }

    func restore() throws -> [HTTPCookie] {
        guard let data = try keychain.read(service: service, account: account) else { return [] }
        let decoded = try JSONDecoder().decode([CodableCookie].self, from: data)
        return decoded.compactMap(\.cookie)
    }

    func clear() {
        keychain.delete(service: service, account: account)
    }
}
