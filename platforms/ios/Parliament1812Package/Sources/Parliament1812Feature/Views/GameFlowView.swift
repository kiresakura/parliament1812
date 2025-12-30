import SwiftUI

/// 遊戲流程控制視圖 - 管理整個遊戲流程和畫面切換
struct GameFlowView: View {
    let roomCode: String
    let currentPlayer: Player
    let isHost: Bool

    @State private var gameState = GameState()
    @State private var showingHostPanel = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Current phase view
            currentPhaseView
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(gameState.currentPhase)

            // Host panel button (floating)
            if isHost && gameState.currentPhase != .waiting && gameState.currentPhase != .finished {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HostPanelButton(isActive: showingHostPanel) {
                            showingHostPanel = true
                        }
                        .padding(.trailing, ParliamentSpacing.md)
                        .padding(.bottom, ParliamentSpacing.xl)
                    }
                }
            }

            // Dice roll overlay for international events (Phase 7 - event2)
            if gameState.showDiceRoll, let diceValue = gameState.diceRollValue {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)

                DiceRollView(
                    diceValue: diceValue,
                    threshold: gameState.diceRollThreshold,
                    triggered: gameState.diceRollTriggered,
                    onComplete: {
                        withAnimation {
                            gameState.showDiceRoll = false
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: gameState.currentPhase)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gameState.showDiceRoll)
        .task {
            await gameState.connectToRoom(roomCode: roomCode, playerId: currentPlayer.id)
        }
        .onDisappear {
            gameState.disconnect()
        }
        .sheet(isPresented: $showingHostPanel) {
            HostPanelView(
                roomCode: roomCode,
                playerId: currentPlayer.id,
                onDismiss: { showingHostPanel = false }
            )
        }
    }

    // MARK: - Current Phase View
    @ViewBuilder
    private var currentPhaseView: some View {
        switch gameState.currentPhase {
        case .waiting:
            WaitingRoomView(
                roomCode: roomCode,
                currentPlayer: currentPlayer,
                isHost: isHost
            )

        case .preparing:
            // Show role reveal with wax seal animation, or waiting view after role revealed
            if gameState.roleRevealed {
                // Player has revealed their role, waiting for host to advance
                ZStack {
                    Color.parliamentBackground.ignoresSafeArea()

                    VStack(spacing: ParliamentSpacing.xl) {
                        // Checkmark icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.parliamentGold)

                        Text("準備就緒")
                            .font(.custom("Songti TC", size: 28).weight(.bold))
                            .foregroundColor(.parliamentTextPrimary)

                        Text("READY")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.parliamentTextMuted)
                            .tracking(2)

                        Spacer().frame(height: ParliamentSpacing.lg)

                        Text("等待主持人開始下一階段...")
                            .font(.parliamentBody)
                            .foregroundColor(.parliamentTextSecondary)

                        Text("Waiting for host to advance...")
                            .font(.system(size: 12))
                            .foregroundColor(.parliamentTextMuted)

                        Spacer().frame(height: ParliamentSpacing.xl)

                        // Show role button to review
                        Button(action: {
                            gameState.showingRole = true
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("查看我的角色")
                                    .font(.parliamentButton)
                            }
                        }
                        .buttonStyle(Civ6ButtonStyle(isEnabled: true, style: .secondary))
                    }
                    .padding(ParliamentSpacing.xl)
                }
                .sheet(isPresented: $gameState.showingRole) {
                    RoleCardSheet(player: currentPlayer)
                }
            } else if let roleType = currentPlayer.roleType {
                RoleRevealView(
                    roleType: roleType.rawValue,
                    roleIndex: currentPlayer.roleIndex ?? 1,
                    onContinue: {
                        gameState.roleRevealed = true
                        // Host can advance phase after all players are ready
                    }
                )
            } else {
                // Fallback: waiting for role assignment
                ZStack {
                    Color.parliamentBackground.ignoresSafeArea()
                    VStack(spacing: ParliamentSpacing.lg) {
                        ProgressView()
                            .tint(.parliamentGold)
                        Text("等待角色分配...")
                            .font(.parliamentBody)
                            .foregroundColor(.parliamentTextMuted)
                    }
                }
            }

        case .conspiracy, .debate, .debate2, .finalDebate:
            DebatePhaseView(
                phase: gameState.currentPhase,
                players: gameState.players,
                currentPlayer: currentPlayer,
                timerEndAt: gameState.timerEndAt,
                onOpenMessages: {
                    gameState.showingMessages = true
                },
                onViewRole: {
                    gameState.showingRole = true
                }
            )
            .safeAreaInset(edge: .top) {
                // Phase progress bar at the top
                PhaseProgressBar(
                    currentPhase: gameState.currentPhase
                )
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.top, ParliamentSpacing.sm)
            }
            .sheet(isPresented: $gameState.showingMessages) {
                MessagesView(
                    roomCode: roomCode,
                    currentPlayer: currentPlayer,
                    players: gameState.players
                )
            }
            .sheet(isPresented: $gameState.showingRole) {
                RoleCardSheet(player: currentPlayer)
            }

        case .event1, .event2:
            if let event = gameState.currentEvent {
                EventPresentationView(
                    event: event,
                    isPresented: Binding(
                        get: { gameState.showingEvent },
                        set: { gameState.showingEvent = $0 }
                    ),
                    onEventComplete: { selectedChoice in
                        // Handle the selected choice
                        if let choice = selectedChoice {
                            Task {
                                await gameState.submitEventChoice(choice: choice)
                            }
                        }
                        // Advance to next phase (host triggers this)
                        if isHost {
                            Task {
                                await gameState.advancePhase()
                            }
                        }
                    }
                )
                .safeAreaInset(edge: .top) {
                    PhaseProgressBar(
                        currentPhase: gameState.currentPhase
                    )
                    .padding(.horizontal, ParliamentSpacing.md)
                    .padding(.top, ParliamentSpacing.sm)
                }
            } else {
                // Fallback: waiting for event data
                ZStack {
                    Color.parliamentBackground.ignoresSafeArea()
                    VStack(spacing: ParliamentSpacing.lg) {
                        ProgressView()
                            .tint(.parliamentGold)
                        Text("等待事件...")
                            .font(.parliamentBody)
                            .foregroundColor(.parliamentTextMuted)
                    }
                }
            }

        case .voteRound1:
            VotingView(
                round: 1,
                options: gameState.voteOptions,
                timerEndAt: gameState.timerEndAt,
                votingProgress: gameState.votingProgress,
                onVote: { choice in
                    Task {
                        await gameState.castVote(round: 1, choice: choice)
                    }
                }
            )
            .safeAreaInset(edge: .top) {
                PhaseProgressBar(
                    currentPhase: gameState.currentPhase
                )
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.top, ParliamentSpacing.sm)
            }

        case .voteRound2:
            VotingView(
                round: 2,
                options: gameState.voteOptions,
                timerEndAt: gameState.timerEndAt,
                votingProgress: gameState.votingProgress,
                onVote: { choice in
                    Task {
                        await gameState.castVote(round: 2, choice: choice)
                    }
                }
            )
            .safeAreaInset(edge: .top) {
                PhaseProgressBar(
                    currentPhase: gameState.currentPhase
                )
                .padding(.horizontal, ParliamentSpacing.md)
                .padding(.top, ParliamentSpacing.sm)
            }

        case .reveal:
            VoteResultView(
                round: 2,
                results: gameState.voteResults,
                voters: gameState.voterInfo,
                winningOption: gameState.winningOptionId,
                onContinue: {
                    // Advance to final results
                }
            )

        case .finished:
            if let winningOption = gameState.voteOptions.first(where: { $0.id == gameState.winningOptionId }) {
                GameResultView(
                    winningOption: winningOption,
                    playerResults: gameState.playerResults,
                    currentPlayerId: currentPlayer.id,
                    onPlayAgain: {
                        // Return to home
                        dismiss()
                    },
                    onExit: {
                        dismiss()
                    }
                )
            }
        }
    }
}

// MARK: - Game State

@MainActor
@Observable
class GameState {
    // Start with .preparing since GameFlowView is only shown after game starts
    var currentPhase: GamePhase = .preparing
    var players: [Player] = []
    var timerEndAt: Date?
    var timerDuration: Int = 0
    var currentEvent: GameEventData?
    var voteOptions: [VoteOption] = []
    var votingProgress: Double = 0
    var voteResults: [VoteResultItem] = []
    var voterInfo: [VoterInfo] = []
    var winningOptionId: String?
    var playerResults: [PlayerGameResult] = []

    var showingMessages = false
    var showingRole = false
    var showingEvent = true  // Always true during event phases
    var roleRevealed = false  // Track if player has revealed their role

    // MARK: - Auto Game Flow State

    // Dice roll state (for international events in Phase 7)
    var diceRollValue: Int?
    var diceRollThreshold: Int = 4
    var diceRollTriggered: Bool = false
    var showDiceRoll: Bool = false

    // Voting state
    var currentVoteRound: Int = 0
    var isVotingActive: Bool = false
    var isAnonymousVote: Bool = true
    var votedCount: Int = 0
    var totalVoters: Int = 0

    // Final results
    var finalResults: [String: Any]?
    var showFinalResults: Bool = false

    private var webSocketTask: URLSessionWebSocketTask?

    // Connection management
    private var isConnected = false
    private var shouldReconnect = true
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var currentRoomCode: String?
    private var currentPlayerId: String?
    private var pollingTask: Task<Void, Never>?

    // Default topic for the game
    static let defaultTopic = DebateTopic(
        id: "machine_question",
        title: "機器問題",
        englishTitle: "The Machine Question",
        description: "隨著工業革命的推進，機器正在取代傳統手工業者。國會必須決定：我們應該如何回應這場變革？",
        options: [
            VoteOption(id: "A", letter: "A", title: "禁止機器", description: "立法禁止工廠使用省力機器"),
            VoteOption(id: "B", letter: "B", title: "保護財產", description: "嚴厲打擊破壞機器的暴民"),
            VoteOption(id: "C", letter: "C", title: "折衷改革", description: "允許機器但立法保障工人權益")
        ]
    )

    init() {
        // Initialize with default vote options
        voteOptions = Self.defaultTopic.options
    }

    func connectToRoom(roomCode: String, playerId: String) async {
        currentRoomCode = roomCode
        currentPlayerId = playerId
        shouldReconnect = true
        reconnectAttempts = 0

        // First, fetch the current room state to get the correct phase
        await fetchInitialState(roomCode: roomCode)

        // Start fallback polling BEFORE WebSocket (since WebSocket loop never returns)
        startPolling()

        // Start WebSocket connection (this will loop forever in receiveMessages)
        await establishWebSocketConnection()
    }

    private func establishWebSocketConnection() async {
        guard let roomCode = currentRoomCode, let playerId = currentPlayerId else { return }

        let wsURL = URL(string: "\(AppConfig.currentWsUrl)/ws/\(roomCode)?player_id=\(playerId)")!
        print("[GameState] 🔌 Connecting to WebSocket: \(wsURL)")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        let session = URLSession(configuration: config)
        webSocketTask = session.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        isConnected = true

        // Start receiving messages (this will loop until disconnected)
        await receiveMessages()
    }

    private func reconnectIfNeeded() async {
        guard shouldReconnect, reconnectAttempts < maxReconnectAttempts else {
            print("[GameState] ❌ Max reconnect attempts reached or reconnection disabled")
            return
        }

        isConnected = false
        reconnectAttempts += 1

        // Exponential backoff: 1s, 2s, 4s, 8s... capped at 30s
        let delay = min(pow(2.0, Double(reconnectAttempts - 1)), 30.0)
        print("[GameState] ⏳ Reconnecting in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")

        try? await Task.sleep(for: .seconds(delay))

        if shouldReconnect {
            await establishWebSocketConnection()
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled && shouldReconnect {
                try? await Task.sleep(for: .seconds(5))  // Poll every 5 seconds

                guard let roomCode = currentRoomCode else { continue }

                // Fetch current phase from API as fallback
                do {
                    let room = try await APIService.shared.getRoom(code: roomCode)
                    if let phase = GamePhase(rawValue: room.phase), phase != currentPhase {
                        print("[GameState] 📡 Polling detected phase change: \(currentPhase) -> \(phase)")
                        withAnimation {
                            currentPhase = phase
                        }
                    }
                } catch {
                    print("[GameState] ⚠️ Polling failed: \(error)")
                }
            }
        }
    }

    /// Fetch current room state from API to sync phase on initial load
    private func fetchInitialState(roomCode: String) async {
        do {
            let room = try await APIService.shared.getRoom(code: roomCode)
            if let phase = GamePhase(rawValue: room.phase) {
                print("[GameState] Fetched initial phase: \(phase) (raw: \(room.phase))")
                withAnimation {
                    currentPhase = phase
                }
            }
            // Also update players list if available
            if let roomPlayers = room.players {
                players = roomPlayers
            }
        } catch {
            print("[GameState] Failed to fetch initial room state: \(error)")
            // Continue with default phase if fetch fails
        }
    }

    func disconnect() {
        print("[GameState] 🔌 Disconnecting...")
        shouldReconnect = false
        isConnected = false
        pollingTask?.cancel()
        pollingTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }

    func castVote(round: Int, choice: String) async {
        let message: [String: Any] = [
            "type": "cast_vote",
            "data": [
                "round": round,
                "choice": choice
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            try? await webSocketTask?.send(.string(string))
        }
    }

    func submitEventChoice(choice: EventChoice) async {
        let message: [String: Any] = [
            "type": "event_choice",
            "data": [
                "event_id": currentEvent?.id ?? "",
                "choice_id": choice.id
            ]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            try? await webSocketTask?.send(.string(string))
        }
    }

    func advancePhase() async {
        let message: [String: Any] = [
            "type": "advance_phase",
            "data": [:]
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            try? await webSocketTask?.send(.string(string))
        }
    }

    private func receiveMessages() async {
        guard let webSocketTask else { return }

        print("[GameState] 📥 Starting to receive WebSocket messages...")

        do {
            while true {
                let message = try await webSocketTask.receive()

                // Reset reconnect attempts on successful message
                reconnectAttempts = 0

                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            print("[GameState] ⚠️ WebSocket error: \(error)")
            isConnected = false

            // Attempt to reconnect if not intentionally disconnected
            if shouldReconnect {
                await reconnectIfNeeded()
            }
        }
    }

    private func handleMessage(_ text: String) {
        print("[GameState] 📩 Received WebSocket message: \(text)")

        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("[GameState] ⚠️ Failed to parse message as JSON")
            return
        }

        print("[GameState] 📋 Message type: \(type)")

        switch type {
        case "player_join":
            if let playerData = json["data"] as? [String: Any] {
                // Add player to list
                handlePlayerJoin(playerData)
            }

        case "player_leave":
            if let playerId = (json["data"] as? [String: Any])?["player_id"] as? String {
                players.removeAll { $0.id == playerId }
            }

        case "phase_change":
            print("[GameState] 🔄 Phase change received, data: \(json["data"] ?? "nil")")
            if let phaseData = json["data"] as? [String: Any],
               let phaseNumber = phaseData["phase"] as? Int,
               let phase = GamePhase(rawValue: phaseNumber) {
                print("[GameState] ✅ Updating phase to: \(phase) (raw: \(phaseNumber))")
                withAnimation {
                    currentPhase = phase
                }
            } else {
                print("[GameState] ❌ Failed to parse phase change data")
            }

        case "timer_sync":
            if let timerData = json["data"] as? [String: Any],
               let endAtString = timerData["end_at"] as? String {
                // Parse ISO 8601 date string with fractional seconds support
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let endAt = formatter.date(from: endAtString) {
                    timerEndAt = endAt
                } else {
                    // Try without fractional seconds
                    formatter.formatOptions = [.withInternetDateTime]
                    timerEndAt = formatter.date(from: endAtString)
                }
                if let duration = timerData["duration"] as? Int {
                    timerDuration = duration
                }
            }

        case "dice_roll":
            if let diceData = json["data"] as? [String: Any],
               let value = diceData["value"] as? Int,
               let threshold = diceData["threshold"] as? Int,
               let triggered = diceData["triggered"] as? Bool {
                print("[GameState] Dice roll - value: \(value), threshold: \(threshold), triggered: \(triggered)")
                diceRollValue = value
                diceRollThreshold = threshold
                diceRollTriggered = triggered
                withAnimation {
                    showDiceRoll = true
                }
                // Play haptic feedback
                HapticManager.shared.playNotification(type: triggered ? .success : .warning)
            }

        case "vote_start":
            if let voteData = json["data"] as? [String: Any],
               let round = voteData["round"] as? Int,
               let isAnonymous = voteData["is_anonymous"] as? Bool {
                print("[GameState] Vote start - round: \(round), anonymous: \(isAnonymous)")
                currentVoteRound = round
                isVotingActive = true
                isAnonymousVote = isAnonymous
                votedCount = 0
                votingProgress = 0
            }

        case "vote_update":
            if let voteData = json["data"] as? [String: Any],
               let progress = voteData["progress"] as? Double {
                withAnimation {
                    votingProgress = progress
                }
                // Extract vote counts for display
                if let voted = voteData["voted_count"] as? Int {
                    votedCount = voted
                }
                if let total = voteData["total_players"] as? Int {
                    totalVoters = total
                }
            }

        case "vote_result":
            if let resultData = json["data"] as? [String: Any] {
                handleVoteResult(resultData)
            }

        case "event_trigger":
            if let eventData = json["data"] as? [String: Any] {
                handleEventTrigger(eventData)
            }

        case "final_results":
            if let resultsData = json["data"] as? [String: Any] {
                print("[GameState] Final results received")
                finalResults = resultsData
                // Parse player results if available
                if let playersData = resultsData["players"] as? [[String: Any]] {
                    playerResults = playersData.compactMap { playerData -> PlayerGameResult? in
                        guard let id = playerData["player_id"] as? String,
                              let nickname = playerData["nickname"] as? String else {
                            return nil
                        }
                        let score = playerData["score"] as? Int ?? 0
                        let missionCompleted = playerData["mission_completed"] as? Bool ?? false
                        let missionTitle = playerData["mission_title"] as? String ?? ""
                        let missionDescription = playerData["mission_description"] as? String ?? ""
                        let missionPoints = playerData["mission_points"] as? Int ?? 0
                        let roleName = playerData["role_name"] as? String ?? ""

                        return PlayerGameResult(
                            id: id,
                            nickname: nickname,
                            roleName: roleName,
                            totalScore: score,
                            missionTitle: missionTitle,
                            missionDescription: missionDescription,
                            missionCompleted: missionCompleted,
                            missionPoints: missionPoints
                        )
                    }
                }
                withAnimation {
                    showFinalResults = true
                }
                HapticManager.shared.playNotification(type: .success)
            }

        default:
            break
        }
    }

    private func handlePlayerJoin(_ data: [String: Any]) {
        guard let id = data["id"] as? String,
              let nickname = data["nickname"] as? String else { return }

        let isHost = data["is_host"] as? Bool ?? false
        let roleTypeString = data["role_type"] as? String
        let roleType = roleTypeString.flatMap { RoleType(rawValue: $0) }
        let roleIndex = data["role_index"] as? Int

        let player = Player(
            id: id,
            nickname: nickname,
            isHost: isHost,
            roleType: roleType,
            roleIndex: roleIndex
        )

        if !players.contains(where: { $0.id == id }) {
            players.append(player)
        }
    }

    private func handleVoteResult(_ data: [String: Any]) {
        print("[GameState] handleVoteResult called with data: \(data.keys)")

        // 使用 "options" 欄位（新格式）或 "results" 欄位（舊格式）
        guard let resultsArray = (data["options"] as? [[String: Any]]) ?? (data["results"] as? [[String: Any]]) else {
            print("[GameState] Failed to parse vote results - no options or results array found")
            return
        }

        print("[GameState] Found \(resultsArray.count) vote options")

        voteResults = resultsArray.compactMap { resultData in
            guard let optionId = resultData["option_id"] as? String,
                  let letter = resultData["letter"] as? String,
                  let title = resultData["title"] as? String,
                  let count = resultData["count"] as? Int,
                  let percentage = resultData["percentage"] as? Double else {
                print("[GameState] Failed to parse option: \(resultData)")
                return nil
            }

            // 解析投票者資訊
            var voters: [VoterInfo] = []
            if let votersArray = resultData["voters"] as? [[String: Any]] {
                voters = votersArray.compactMap { voterData in
                    guard let playerId = voterData["player_id"] as? String,
                          let nickname = voterData["nickname"] as? String else {
                        return nil
                    }
                    return VoterInfo(playerId: playerId, nickname: nickname)
                }
            }

            print("[GameState] Parsed option \(letter): \(title) - \(count) votes (\(percentage)%) - \(voters.count) voters")

            return VoteResultItem(
                optionId: optionId,
                letter: letter,
                title: title,
                count: count,
                percentage: percentage,
                voters: voters
            )
        }

        winningOptionId = data["winning_option"] as? String ?? data["winner"] as? String
        print("[GameState] Vote results parsed: \(voteResults.count) options, winner: \(winningOptionId ?? "none")")
    }

    private func handleEventTrigger(_ data: [String: Any]) {
        guard let eventInfo = data["event"] as? [String: Any],
              let id = eventInfo["id"] as? String,
              let title = eventInfo["title"] as? String,
              let description = eventInfo["description"] as? String else {
            return
        }

        // Parse category
        let categoryString = eventInfo["category"] as? String ?? "domestic"
        let category: EventCategory = categoryString == "international" ? .international : .domestic

        // Parse event type
        let typeString = eventInfo["type"] as? String ?? "political"
        let eventType = EventType(rawValue: typeString) ?? .political

        // Parse severity
        let severity = eventInfo["severity"] as? Int ?? 2

        // Parse effects
        var effects: [EventEffect] = []
        if let effectsArray = eventInfo["effects"] as? [[String: Any]] {
            for effectData in effectsArray {
                let targetRole = effectData["target_role"] as? String
                let supportChange = effectData["support_change"] as? Int ?? 0
                let reputationChange = effectData["reputation_change"] as? Int ?? 0
                let condition = effectData["condition"] as? String

                effects.append(EventEffect(
                    targetRole: targetRole,
                    supportChange: supportChange,
                    reputationChange: reputationChange,
                    condition: condition
                ))
            }
        }

        // Parse choices
        var choices: [EventChoice]? = nil
        if let choicesArray = eventInfo["choices"] as? [[String: Any]] {
            choices = choicesArray.compactMap { choiceData in
                guard let choiceId = choiceData["id"] as? String,
                      let choiceTitle = choiceData["title"] as? String,
                      let choiceDescription = choiceData["description"] as? String else {
                    return nil
                }

                var choiceEffects: [EventEffect] = []
                if let choiceEffectsArray = choiceData["effects"] as? [[String: Any]] {
                    for effectData in choiceEffectsArray {
                        let targetRole = effectData["target_role"] as? String
                        let supportChange = effectData["support_change"] as? Int ?? 0
                        let reputationChange = effectData["reputation_change"] as? Int ?? 0
                        let condition = effectData["condition"] as? String

                        choiceEffects.append(EventEffect(
                            targetRole: targetRole,
                            supportChange: supportChange,
                            reputationChange: reputationChange,
                            condition: condition
                        ))
                    }
                }

                return EventChoice(
                    id: choiceId,
                    title: choiceTitle,
                    description: choiceDescription,
                    effects: choiceEffects
                )
            }
        }

        // Check if it's a predefined event
        if let predefinedEvent = EventDatabase.allEvents.first(where: { $0.id == id }) {
            currentEvent = predefinedEvent
        } else {
            // Create dynamic event from server data
            currentEvent = GameEventData(
                id: id,
                title: title,
                englishTitle: eventInfo["english_title"] as? String ?? title,
                description: description,
                category: category,
                type: eventType,
                severity: severity,
                effects: effects,
                choices: choices
            )
        }
    }
}

// MARK: - Supporting Views

/// 主持人控制面板浮動按鈕
struct HostPanelButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.parliamentGold)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.parliamentBackground)
            }
        }
        .accessibilityLabel("主持人控制面板")
        .accessibilityHint("打開主持人控制面板以管理遊戲")
    }
}

struct RoleCardSheet: View {
    let player: Player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.parliamentBackground.ignoresSafeArea()

                RoleCardView(player: player)
                    .padding()
            }
            .navigationTitle("我的角色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.parliamentGold)
                }
            }
        }
    }
}


// MARK: - Preview

#Preview("Game Flow - Debate") {
    GameFlowView(
        roomCode: "ABC123",
        currentPlayer: Player(
            id: "1",
            nickname: "威廉",
            isHost: true,
            roleType: .mp,
            roleIndex: 1
        ),
        isHost: true
    )
}

#Preview("Event Presentation") {
    EventPresentationView(
        event: EventDatabase.allEvents[0],
        isPresented: .constant(true),
        onEventComplete: { _ in }
    )
}

#Preview("Event Card") {
    ZStack {
        Color.parliamentBackground.ignoresSafeArea()
        EventCardView(event: EventDatabase.allEvents[0])
            .padding()
    }
}
