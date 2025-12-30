import Foundation

// MARK: - Vote Option (API Model)
struct VoteOption: Codable, Identifiable, Sendable {
    let id: String
    let letter: String
    let title: String
    let description: String
    let isHidden: Bool?

    private enum CodingKeys: String, CodingKey {
        case key
        case title
        case description
        case isHidden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        self.id = key
        self.letter = key
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .key)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(isHidden, forKey: .isHidden)
    }

    init(id: String, letter: String, title: String, description: String, isHidden: Bool? = nil) {
        self.id = id
        self.letter = letter
        self.title = title
        self.description = description
        self.isHidden = isHidden
    }
}

// MARK: - Vote Response
struct VoteResponse: Codable, Sendable {
    let id: String
    let playerId: String
    let round: Int
    let choice: String
    let votedAt: String
}

// MARK: - Vote Progress
struct VoteProgress: Codable, Sendable {
    let round: Int
    let votedCount: Int
    let totalPlayers: Int
    let progress: Double
    let isComplete: Bool?
}

// MARK: - Vote Result
struct VoteResult: Codable, Sendable {
    let round: Int
    let percentages: [String: Double]
    let winner: String?
    let votes: [PlayerVote]?
}

struct PlayerVote: Codable, Sendable {
    let playerId: String
    let nickname: String
    let choice: String
}

// MARK: - My Vote Response
struct MyVoteResponse: Codable, Sendable {
    let hasVoted: Bool
    let vote: MyVoteDetail?
}

struct MyVoteDetail: Codable, Sendable {
    let id: String
    let round: Int
    let choice: String
    let votedAt: String
}
