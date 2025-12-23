import Foundation

@Observable
@MainActor
final class WebSocketService: Sendable {
    private var webSocket: URLSessionWebSocketTask?
    private(set) var isConnected = false
    private(set) var lastError: Error?

    // 使用 snake_case 解碼策略的 decoder
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // Event callbacks
    var onPlayerJoined: (@Sendable (Player) -> Void)?
    var onPlayerLeft: (@Sendable (String) -> Void)?
    var onPlayerReady: (@Sendable (String, Bool) -> Void)?
    var onRoleAssigned: (@Sendable (String, String, Int) -> Void)?
    var onGameStarted: (@Sendable () -> Void)?
    var onPhaseChanged: (@Sendable (GamePhase) -> Void)?

    nonisolated init() {}

    func connect(roomCode: String, playerId: String) {
        let urlString = "\(AppConfig.currentWsUrl)/ws/\(roomCode)?player_id=\(playerId)"
        guard let url = URL(string: urlString) else {
            print("WebSocket: Invalid URL")
            return
        }

        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        isConnected = true
        lastError = nil

        receiveMessage()
        print("WebSocket: Connected to \(urlString)")
    }

    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        webSocket = nil
        print("WebSocket: Disconnected")
    }

    func send(type: String, data: [String: Any]) async throws {
        var message: [String: Any] = ["type": type]
        message["data"] = data

        let jsonData = try JSONSerialization.data(withJSONObject: message)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw WebSocketError.encodingFailed
        }

        try await webSocket?.send(.string(jsonString))
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    // 繼續監聽
                    self?.receiveMessage()

                case .failure(let error):
                    print("WebSocket error: \(error)")
                    self?.isConnected = false
                    self?.lastError = error
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("WebSocket: Failed to parse message")
            return
        }

        print("WebSocket: Received \(type)")

        switch type {
        case "player_join":
            // 後端發送的數據結構: { player_id, nickname, role_type, is_host }
            if let playerData = json["data"] as? [String: Any],
               let playerId = playerData["player_id"] as? String,
               let nickname = playerData["nickname"] as? String {
                let roleTypeString = playerData["role_type"] as? String
                let roleType = roleTypeString.flatMap { RoleType(rawValue: $0) }
                let isHost = playerData["is_host"] as? Bool ?? false
                let isReady = playerData["is_ready"] as? Bool ?? false

                // 創建 Player 對象
                let player = Player(
                    id: playerId,
                    nickname: nickname,
                    isHost: isHost,
                    roleType: roleType,
                    roleIndex: nil,
                    isReady: isReady
                )
                print("WebSocket: Player joined - \(player.nickname), isHost: \(player.isHost)")
                onPlayerJoined?(player)
            }

        case "player_leave":
            if let playerId = (json["data"] as? [String: Any])?["player_id"] as? String {
                onPlayerLeft?(playerId)
            }

        case "player_ready":
            if let data = json["data"] as? [String: Any],
               let playerId = data["player_id"] as? String,
               let isReady = data["is_ready"] as? Bool {
                onPlayerReady?(playerId, isReady)
            }

        case "role_assigned":
            if let data = json["data"] as? [String: Any],
               let playerId = data["player_id"] as? String,
               let roleType = data["role_type"] as? String,
               let roleIndex = data["role_index"] as? Int {
                onRoleAssigned?(playerId, roleType, roleIndex)
            }

        case "game_started":
            onGameStarted?()

        case "phase_change":
            if let data = json["data"] as? [String: Any],
               let phaseRaw = data["phase"] as? Int,
               let phase = GamePhase(rawValue: phaseRaw) {
                onPhaseChanged?(phase)
            }

        default:
            print("WebSocket: Unknown message type: \(type)")
        }
    }
}

enum WebSocketError: LocalizedError {
    case encodingFailed
    case notConnected

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "訊息編碼失敗"
        case .notConnected:
            return "WebSocket 未連線"
        }
    }
}
