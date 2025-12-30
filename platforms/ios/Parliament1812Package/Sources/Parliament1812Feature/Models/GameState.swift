import Foundation

enum GamePhase: Int, Codable, Sendable {
    case waiting = 1
    case preparing = 2
    case conspiracy = 3
    case debate = 4
    case event1 = 5
    case debate2 = 6
    case event2 = 7
    case voteRound1 = 8
    case finalDebate = 9
    case voteRound2 = 10
    case reveal = 11
    case finished = 12

    static var debatePhases: [GamePhase] {
        [.preparing, .conspiracy, .debate, .event1, .debate2, .event2, .voteRound1, .finalDebate, .voteRound2, .reveal]
    }

    var displayName: String {
        switch self {
        case .waiting: return "等待中"
        case .preparing: return "角色研究"
        case .conspiracy: return "私下密謀"
        case .debate: return "開場陳述"
        case .event1: return "突發事件"
        case .debate2: return "自由辯論"
        case .event2: return "突發事件"
        case .voteRound1: return "第一輪投票"
        case .finalDebate: return "最後攻防"
        case .voteRound2: return "記名投票"
        case .reveal: return "結果揭曉"
        case .finished: return "遊戲結束"
        }
    }

    var englishName: String {
        switch self {
        case .waiting: return "WAITING"
        case .preparing: return "PREPARATION"
        case .conspiracy: return "CONSPIRACY"
        case .debate: return "OPENING STATEMENTS"
        case .event1: return "SUDDEN EVENT"
        case .debate2: return "FREE DEBATE"
        case .event2: return "SUDDEN EVENT"
        case .voteRound1: return "FIRST VOTE"
        case .finalDebate: return "FINAL ARGUMENTS"
        case .voteRound2: return "ROLL CALL VOTE"
        case .reveal: return "REVELATION"
        case .finished: return "FINISHED"
        }
    }

    var description: String {
        switch self {
        case .waiting: return "等待更多議員加入..."
        case .preparing: return "研究您的角色背景，與陣營成員討論策略"
        case .conspiracy: return "這是密謀的時刻。與盟友私下交流，達成秘密協議"
        case .debate: return "各方代表發表開場陳述，闡明立場"
        case .event1: return "突發事件打破平靜，局勢可能發生變化"
        case .debate2: return "自由辯論時間。說服、質疑、反駁！"
        case .event2: return "又一個突發事件，最終局勢即將明朗"
        case .voteRound1: return "匿名投票進行中，只公布比例"
        case .finalDebate: return "最後的說服機會，改變搖擺票的關鍵"
        case .voteRound2: return "記名投票，每一票都將被記錄"
        case .reveal: return "揭曉秘密任務，計算最終得分"
        case .finished: return "遊戲已結束"
        }
    }

    var hint: String? {
        switch self {
        case .conspiracy: return "點擊玩家頭像發送密信"
        case .debate, .debate2, .finalDebate: return "留意他人的發言，尋找弱點"
        case .voteRound1, .voteRound2: return "您的秘密任務可能影響投票策略"
        default: return nil
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .waiting: return 0
        case .preparing: return 15 * 60  // 15 minutes
        case .conspiracy: return 10 * 60  // 10 minutes
        case .debate: return 25 * 60  // 25 minutes
        case .event1, .event2: return 5 * 60  // 5 minutes
        case .debate2: return 30 * 60  // 30 minutes
        case .voteRound1, .voteRound2: return 5 * 60  // 5 minutes
        case .finalDebate: return 10 * 60  // 10 minutes
        case .reveal: return 10 * 60  // 10 minutes
        case .finished: return 0
        }
    }
}

// MARK: - Game Flow State
/// Observable state for automatic game flow events
@Observable
@MainActor
final class GameFlowState: Sendable {
    // Current phase and timer
    var currentPhase: GamePhase = .waiting
    var timerEndAt: Date?
    var timerDuration: Int = 0

    // Dice roll state (for international events)
    var diceRoll: DiceRollResult?
    var showDiceRoll: Bool = false

    // Event state
    var currentEvent: GameEvent?
    var showEvent: Bool = false

    // Voting state
    var currentVoteRound: Int = 0
    var isVotingActive: Bool = false
    var isAnonymousVote: Bool = true
    var voteProgress: VoteProgressState = VoteProgressState()
    var voteResult: VoteResultState?

    // Final results
    var finalResults: FinalResultsState?
    var showFinalResults: Bool = false

    nonisolated init() {}

    func updatePhase(_ phase: GamePhase) {
        currentPhase = phase
        // Reset dice roll when phase changes
        if phase != .event2 {
            showDiceRoll = false
            diceRoll = nil
        }
    }

    func updateTimer(endAt: Date, duration: Int) {
        timerEndAt = endAt
        timerDuration = duration
    }

    func handleDiceRoll(value: Int, threshold: Int, triggered: Bool) {
        diceRoll = DiceRollResult(value: value, threshold: threshold, triggered: triggered)
        showDiceRoll = true
    }

    func handleEventTrigger(eventId: String, title: String, description: String, effectType: String?) {
        currentEvent = GameEvent(
            id: eventId,
            title: title,
            description: description,
            effectType: effectType
        )
        showEvent = true
    }

    func handleVoteStart(round: Int, isAnonymous: Bool) {
        currentVoteRound = round
        isVotingActive = true
        isAnonymousVote = isAnonymous
        voteProgress = VoteProgressState()
        voteResult = nil
    }

    func handleVoteUpdate(round: Int, votedCount: Int, totalPlayers: Int, progress: Double) {
        if round == currentVoteRound {
            voteProgress = VoteProgressState(
                votedCount: votedCount,
                totalPlayers: totalPlayers,
                progress: progress,
                isComplete: votedCount >= totalPlayers
            )
        }
    }

    func handleVoteResult(round: Int, results: [String: Any]) {
        isVotingActive = false
        voteProgress.isComplete = true

        // Parse results based on round
        if round == 1 {
            // Anonymous vote - only percentages
            if let percentages = results["percentages"] as? [String: Double] {
                voteResult = VoteResultState(
                    round: round,
                    percentages: percentages,
                    playerVotes: nil,
                    winningChoice: results["winning_choice"] as? String
                )
            }
        } else {
            // Named vote - full results
            var playerVotes: [String: String] = [:]
            if let votes = results["votes"] as? [[String: Any]] {
                for vote in votes {
                    if let playerId = vote["player_id"] as? String,
                       let choice = vote["choice"] as? String {
                        playerVotes[playerId] = choice
                    }
                }
            }
            voteResult = VoteResultState(
                round: round,
                percentages: results["percentages"] as? [String: Double] ?? [:],
                playerVotes: playerVotes,
                winningChoice: results["winning_choice"] as? String
            )
        }
    }

    func handleFinalResults(_ results: [String: Any]) {
        finalResults = FinalResultsState(
            round1Result: results["round1"] as? [String: Any],
            round2Result: results["round2"] as? [String: Any],
            winningChoice: results["winning_choice"] as? String
        )
        showFinalResults = true
    }

    func dismissDiceRoll() {
        showDiceRoll = false
    }

    func dismissEvent() {
        showEvent = false
    }
}

// MARK: - Supporting Types

struct DiceRollResult: Sendable {
    let value: Int
    let threshold: Int
    let triggered: Bool
}

struct GameEvent: Sendable, Identifiable {
    let id: String
    let title: String
    let description: String
    let effectType: String?
}

struct VoteProgressState: Sendable {
    var votedCount: Int = 0
    var totalPlayers: Int = 0
    var progress: Double = 0
    var isComplete: Bool = false
}

struct VoteResultState: Sendable {
    let round: Int
    let percentages: [String: Double]
    let playerVotes: [String: String]?
    let winningChoice: String?
}

struct VoteRoundResult: Sendable {
    let round: Int
    let percentages: [String: Double]
    let playerVotes: [String: String]?
    let winningChoice: String?
    let totalVotes: Int

    init(from dict: [String: Any]) {
        self.round = dict["round"] as? Int ?? 0
        self.percentages = dict["percentages"] as? [String: Double] ?? [:]
        self.playerVotes = dict["player_votes"] as? [String: String]
        self.winningChoice = dict["winning_choice"] as? String
        self.totalVotes = dict["total_votes"] as? Int ?? 0
    }
}

struct FinalResultsState: Sendable {
    let round1Result: VoteRoundResult?
    let round2Result: VoteRoundResult?
    let winningChoice: String?

    init(round1Result: [String: Any]?, round2Result: [String: Any]?, winningChoice: String?) {
        self.round1Result = round1Result.map { VoteRoundResult(from: $0) }
        self.round2Result = round2Result.map { VoteRoundResult(from: $0) }
        self.winningChoice = winningChoice
    }
}

enum VoteChoice: String, Codable, Sendable {
    case A = "A"  // 禁止機器
    case B = "B"  // 保護財產
    case C = "C"  // 折衷改革
    case D = "D"  // 皇家調查 (隱藏選項)

    var displayName: String {
        switch self {
        case .A: return "禁止機器"
        case .B: return "保護財產"
        case .C: return "折衷改革"
        case .D: return "皇家調查"
        }
    }

    var description: String {
        switch self {
        case .A: return "立法禁止工廠使用省力機器"
        case .B: return "嚴厲打擊破壞機器的暴民"
        case .C: return "允許機器但立法保障工人權益"
        case .D: return "由皇室調查委員會處理"
        }
    }
}
