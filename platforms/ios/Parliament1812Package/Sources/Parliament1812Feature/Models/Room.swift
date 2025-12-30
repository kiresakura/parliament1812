import Foundation

struct Room: Codable, Sendable {
    let id: String?
    let code: String
    var players: [Player]?
    let status: RoomStatus
    let phase: Int
    let currentRound: Int?
    let timerEndAt: String?
    let createdAt: String
    let playerCount: Int?

    // Custom Codable to handle missing fields and type conversions
    enum CodingKeys: String, CodingKey {
        case id, code, players, status, phase, currentRound, timerEndAt, createdAt, playerCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id can be UUID string from backend
        id = try container.decodeIfPresent(String.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        players = try container.decodeIfPresent([Player].self, forKey: .players)

        // status can be string or enum
        if let statusString = try? container.decode(String.self, forKey: .status) {
            status = RoomStatus(rawValue: statusString) ?? .waiting
        } else {
            status = try container.decode(RoomStatus.self, forKey: .status)
        }

        phase = try container.decode(Int.self, forKey: .phase)
        currentRound = try container.decodeIfPresent(Int.self, forKey: .currentRound)

        // timerEndAt is always a string from backend
        timerEndAt = try container.decodeIfPresent(String.self, forKey: .timerEndAt)

        // createdAt is always a string from backend (ISO8601 format)
        createdAt = try container.decode(String.self, forKey: .createdAt)

        playerCount = try container.decodeIfPresent(Int.self, forKey: .playerCount)
    }
}

enum RoomStatus: String, Codable, Sendable {
    case waiting
    case playing
    case finished
}

struct CreateRoomResponse: Codable, Sendable {
    let code: String
    let roomId: String
    let playerId: String
    let message: String?
}

struct JoinRoomResponse: Codable, Sendable {
    let playerId: String
    let roomCode: String
    let message: String?
}

// MARK: - Timer Response

struct TimerResponse: Codable, Sendable {
    let timerEndAt: String
    let message: String?
}

// MARK: - Event Data (API Response)

/// 事件資料（用於 API 回應）
struct EventData: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let effectType: String?
    let severity: Int?
    let category: String?
}
