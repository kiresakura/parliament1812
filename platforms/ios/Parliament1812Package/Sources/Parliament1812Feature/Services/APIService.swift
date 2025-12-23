import Foundation

actor APIService {
    static let shared = APIService()

    private let baseURL: String
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    init() {
        self.baseURL = AppConfig.currentApiUrl
    }

    // MARK: - Room Management

    /// 建立房間
    func createRoom(hostNickname: String) async throws -> CreateRoomResponse {
        let url = URL(string: "\(baseURL)/api/rooms")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["host_nickname": hostNickname])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(CreateRoomResponse.self, from: data)
    }

    /// 加入房間
    func joinRoom(code: String, nickname: String) async throws -> JoinRoomResponse {
        let url = URL(string: "\(baseURL)/api/rooms/\(code)/join")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["nickname": nickname])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(JoinRoomResponse.self, from: data)
    }

    /// 取得房間資訊
    func getRoom(code: String) async throws -> Room {
        let url = URL(string: "\(baseURL)/api/rooms/\(code)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try decoder.decode(Room.self, from: data)
    }

    /// 取得房間玩家列表
    func getPlayers(roomCode: String) async throws -> [Player] {
        let url = URL(string: "\(baseURL)/api/rooms/\(roomCode)/players")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try decoder.decode([Player].self, from: data)
    }

    /// 離開房間
    func leaveRoom(code: String, playerId: String) async throws {
        var components = URLComponents(string: "\(baseURL)/api/rooms/\(code)/leave")!
        components.queryItems = [URLQueryItem(name: "player_id", value: playerId)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)
        // 204 No Content is expected, also accept 200-299
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            try validateResponse(response)
            return
        }
    }

    /// 設定玩家準備狀態
    func setReady(playerId: String, isReady: Bool) async throws -> Player {
        let url = URL(string: "\(baseURL)/api/players/\(playerId)/ready")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["is_ready": isReady])

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(Player.self, from: data)
    }

    /// 切換遊戲階段（僅房主）
    func changePhase(roomCode: String, phase: Int, playerId: String) async throws {
        var components = URLComponents(string: "\(baseURL)/api/rooms/\(roomCode)/phase")!
        components.queryItems = [URLQueryItem(name: "player_id", value: playerId)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["phase": phase])

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    /// 開始遊戲（僅房主）- 驗證所有玩家已準備
    func startGame(roomCode: String, playerId: String) async throws {
        var components = URLComponents(string: "\(baseURL)/api/rooms/\(roomCode)/start")!
        components.queryItems = [URLQueryItem(name: "player_id", value: playerId)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - NFC

    /// NFC 掃卡驗證（UID 綁定防偽格式）
    func scanNFC(_ request: NFCScanRequest) async throws -> NFCScanResponse {
        var components = URLComponents(string: "\(baseURL)/api/rooms/\(request.roomCode)/scan-nfc")!
        components.queryItems = [URLQueryItem(name: "player_id", value: request.playerId)]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // UID 綁定防偽格式
        let body: [String: String] = [
            "card_id": request.cardId,
            "signature": request.signature,
            "uid": request.uid
        ]

        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)
        return try decoder.decode(NFCScanResponse.self, from: data)
    }

    /// 手動角色分配（DEBUG/模擬器測試用）
    /// - Parameters:
    ///   - roomCode: 房間碼
    ///   - playerId: 玩家 ID
    ///   - roleCode: 角色代碼（如 W01, F02, L03, R04, M01）
    /// - Returns: 角色分配結果
    func assignRoleManually(roomCode: String, playerId: String, roleCode: String) async throws -> NFCScanResponse {
        let url = URL(string: "\(baseURL)/api/rooms/\(roomCode)/assign-role-manual")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "player_id": playerId,
            "role_code": roleCode
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(NFCScanResponse.self, from: data)
    }

    // MARK: - Roles

    /// 取得所有角色
    func getRoles() async throws -> [Role] {
        let url = URL(string: "\(baseURL)/api/roles")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try decoder.decode([Role].self, from: data)
    }

    /// 取得特定角色
    func getRole(type: String) async throws -> Role {
        let url = URL(string: "\(baseURL)/api/roles/\(type)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        return try decoder.decode(Role.self, from: data)
    }

    // MARK: - Helper

    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            // Try to extract the actual error message from the response
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                throw APIError.badRequestWithMessage(detail)
            }
            throw APIError.badRequest
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case badRequest
    case badRequestWithMessage(String)
    case unauthorized
    case notFound
    case serverError
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "無效的回應"
        case .badRequest:
            return "請求格式錯誤"
        case .badRequestWithMessage(let message):
            return message
        case .unauthorized:
            return "未授權"
        case .notFound:
            return "找不到資源"
        case .serverError:
            return "伺服器錯誤"
        case .unknown(let code):
            return "未知錯誤 (\(code))"
        }
    }
}
