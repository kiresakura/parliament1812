import Foundation

struct Player: Codable, Identifiable, Sendable {
    let id: String
    let nickname: String
    let isHost: Bool
    var roleType: RoleType?
    var roleIndex: Int?
    var isReady: Bool

    var hasRole: Bool {
        roleType != nil && roleIndex != nil
    }

    // Custom Codable to handle string-based roleType from API
    // NOTE: APIService uses convertFromSnakeCase, so CodingKeys should use camelCase names
    // The decoder automatically converts is_host → isHost, role_type → roleType, etc.
    enum CodingKeys: String, CodingKey {
        case id, nickname, isHost, roleType, roleIndex, isReady
    }

    init(id: String, nickname: String, isHost: Bool, roleType: RoleType? = nil, roleIndex: Int? = nil, isReady: Bool = false) {
        self.id = id
        self.nickname = nickname
        self.isHost = isHost
        self.roleType = roleType
        self.roleIndex = roleIndex
        self.isReady = isReady
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        isHost = try container.decodeIfPresent(Bool.self, forKey: .isHost) ?? false
        roleIndex = try container.decodeIfPresent(Int.self, forKey: .roleIndex)
        isReady = try container.decodeIfPresent(Bool.self, forKey: .isReady) ?? false

        // Handle string-based roleType from API
        if let roleTypeString = try container.decodeIfPresent(String.self, forKey: .roleType) {
            roleType = RoleType(rawValue: roleTypeString)
        } else {
            roleType = nil
        }
    }
}
