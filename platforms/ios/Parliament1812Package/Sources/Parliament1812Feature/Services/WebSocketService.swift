import Foundation

@Observable
@MainActor
final class WebSocketService: Sendable {
    private var webSocket: URLSessionWebSocketTask?
    private(set) var isConnected = false
    private(set) var lastError: Error?

    // Reconnection state
    private var currentRoomCode: String?
    private var currentPlayerId: String?
    private var reconnectAttempts = 0
    private var isReconnecting = false
    private let maxReconnectAttempts = 5
    private var shouldReconnect = true

    // 使用 snake_case 解碼策略的 decoder
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // Event callbacks - Player Events
    var onPlayerJoined: (@Sendable (Player) -> Void)?
    var onPlayerLeft: (@Sendable (String) -> Void)?
    var onPlayerReady: (@Sendable (String, Bool) -> Void)?
    var onRoleAssigned: (@Sendable (String, String, Int) -> Void)?
    var onGameStarted: (@Sendable () -> Void)?
    var onPhaseChanged: (@Sendable (GamePhase) -> Void)?
    var onConnectionStatusChanged: (@Sendable (Bool) -> Void)?

    // Event callbacks - Auto Game Flow Events
    /// Timer synchronization: (endAt: Date, duration: Int)
    var onTimerSync: (@Sendable (Date, Int) -> Void)?
    /// Dice roll result: (value: Int, threshold: Int, triggered: Bool)
    var onDiceRoll: (@Sendable (Int, Int, Bool) -> Void)?
    /// Vote phase started: (round: Int, isAnonymous: Bool)
    var onVoteStart: (@Sendable (Int, Bool) -> Void)?
    /// Vote progress update: (round: Int, votedCount: Int, totalPlayers: Int, progress: Double)
    var onVoteUpdate: (@Sendable (Int, Int, Int, Double) -> Void)?
    /// Vote result: (round: Int, results: [String: Any])
    var onVoteResult: (@Sendable (Int, [String: Any]) -> Void)?
    /// Event triggered: (eventId: String, title: String, description: String, effectType: String?)
    var onEventTrigger: (@Sendable (String, String, String, String?) -> Void)?
    /// Final game results
    var onFinalResults: (@Sendable ([String: Any]) -> Void)?

    nonisolated init() {}

    func connect(roomCode: String, playerId: String) {
        // Store for reconnection
        currentRoomCode = roomCode
        currentPlayerId = playerId
        shouldReconnect = true
        reconnectAttempts = 0

        performConnect(roomCode: roomCode, playerId: playerId)
    }

    private func performConnect(roomCode: String, playerId: String) {
        let urlString = "\(AppConfig.currentWsUrl)/ws/\(roomCode)?player_id=\(playerId)"
        guard let url = URL(string: urlString) else {
            print("WebSocket: Invalid URL: \(urlString)")
            return
        }

        print("WebSocket: Attempting connection to \(urlString)")

        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        // Don't set isConnected = true immediately, wait for first successful receive
        lastError = nil
        isReconnecting = false

        receiveMessage()
        print("WebSocket: Connection initiated to \(urlString)")
    }

    func disconnect() {
        shouldReconnect = false
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        webSocket = nil
        currentRoomCode = nil
        currentPlayerId = nil
        print("WebSocket: Disconnected intentionally")
    }

    private func attemptReconnect() {
        guard shouldReconnect,
              let roomCode = currentRoomCode,
              let playerId = currentPlayerId,
              reconnectAttempts < maxReconnectAttempts,
              !isReconnecting else {
            if reconnectAttempts >= maxReconnectAttempts {
                print("WebSocket: Max reconnection attempts reached (\(maxReconnectAttempts))")
            }
            return
        }

        isReconnecting = true
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * AppConfig.wsReconnectDelay, 15.0)

        print("WebSocket: Scheduling reconnection attempt \(reconnectAttempts)/\(maxReconnectAttempts) in \(delay)s")

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard shouldReconnect else {
                print("WebSocket: Reconnection cancelled")
                return
            }
            print("WebSocket: Executing reconnection attempt \(reconnectAttempts)")
            performConnect(roomCode: roomCode, playerId: playerId)
        }
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
                    // First successful message means we're connected
                    if self?.isConnected == false {
                        self?.isConnected = true
                        self?.reconnectAttempts = 0
                        print("WebSocket: Connection confirmed (first message received)")
                        self?.onConnectionStatusChanged?(true)
                    }

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
                    // 繼續監聯
                    self?.receiveMessage()

                case .failure(let error):
                    let wasConnected = self?.isConnected ?? false
                    print("WebSocket error: \(error.localizedDescription), wasConnected: \(wasConnected)")
                    self?.isConnected = false
                    self?.lastError = error
                    self?.onConnectionStatusChanged?(false)

                    // Attempt reconnection
                    self?.attemptReconnect()
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("WebSocket: Failed to parse message: \(text.prefix(100))")
            return
        }

        // Skip logging for ping/pong to reduce noise
        if type != "ping" && type != "pong" {
            print("WebSocket: Received \(type)")
        }

        switch type {
        case "ping":
            // Respond to server ping with pong
            Task {
                try? await send(type: "pong", data: [:])
            }
            return

        case "pong":
            // Server acknowledged our ping, nothing to do
            return

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
            print("DEBUG WebSocket: phase_change received, raw json: \(json)")
            if let data = json["data"] as? [String: Any] {
                print("DEBUG WebSocket: phase_change data: \(data)")
                if let phaseRaw = data["phase"] as? Int {
                    print("DEBUG WebSocket: phaseRaw = \(phaseRaw)")
                    if let phase = GamePhase(rawValue: phaseRaw) {
                        print("DEBUG WebSocket: Calling onPhaseChanged with phase: \(phase)")
                        onPhaseChanged?(phase)
                    } else {
                        print("DEBUG WebSocket: Failed to create GamePhase from raw value \(phaseRaw)")
                    }
                } else {
                    print("DEBUG WebSocket: Failed to get phase as Int from data")
                }
            } else {
                print("DEBUG WebSocket: Failed to get data dictionary from json")
            }

        // MARK: - Auto Game Flow Events

        case "timer_sync":
            if let data = json["data"] as? [String: Any],
               let endAtString = data["end_at"] as? String,
               let duration = data["duration"] as? Int {
                // Parse ISO 8601 date string
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let endAt = formatter.date(from: endAtString) {
                    print("WebSocket: Timer sync - endAt: \(endAt), duration: \(duration)s")
                    onTimerSync?(endAt, duration)
                } else {
                    // Try without fractional seconds
                    formatter.formatOptions = [.withInternetDateTime]
                    if let endAt = formatter.date(from: endAtString) {
                        print("WebSocket: Timer sync - endAt: \(endAt), duration: \(duration)s")
                        onTimerSync?(endAt, duration)
                    } else {
                        print("WebSocket: Failed to parse timer end_at: \(endAtString)")
                    }
                }
            }

        case "dice_roll":
            if let data = json["data"] as? [String: Any],
               let value = data["value"] as? Int,
               let threshold = data["threshold"] as? Int,
               let triggered = data["triggered"] as? Bool {
                print("WebSocket: Dice roll - value: \(value), threshold: \(threshold), triggered: \(triggered)")
                onDiceRoll?(value, threshold, triggered)
            }

        case "vote_start":
            if let data = json["data"] as? [String: Any],
               let round = data["round"] as? Int,
               let isAnonymous = data["is_anonymous"] as? Bool {
                print("WebSocket: Vote start - round: \(round), anonymous: \(isAnonymous)")
                onVoteStart?(round, isAnonymous)
            }

        case "vote_update":
            if let data = json["data"] as? [String: Any],
               let round = data["round"] as? Int,
               let votedCount = data["voted_count"] as? Int,
               let totalPlayers = data["total_players"] as? Int,
               let progress = data["progress"] as? Double {
                print("WebSocket: Vote update - round: \(round), \(votedCount)/\(totalPlayers)")
                onVoteUpdate?(round, votedCount, totalPlayers, progress)
            }

        case "vote_result":
            if let data = json["data"] as? [String: Any],
               let round = data["round"] as? Int {
                print("WebSocket: Vote result - round: \(round)")
                onVoteResult?(round, data)
            }

        case "event_trigger":
            if let data = json["data"] as? [String: Any],
               let eventId = data["event_id"] as? String,
               let title = data["event_title"] as? String,
               let description = data["event_description"] as? String {
                let effectType = data["effect_type"] as? String
                print("WebSocket: Event triggered - \(title)")
                onEventTrigger?(eventId, title, description, effectType)
            }

        case "final_results":
            if let data = json["data"] as? [String: Any] {
                print("WebSocket: Final results received")
                onFinalResults?(data)
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
