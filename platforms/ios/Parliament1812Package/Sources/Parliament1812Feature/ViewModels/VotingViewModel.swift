import Foundation
import Combine

/// 投票 UI 狀態
struct VoteUiState: Sendable {
    var isLoading: Bool = false
    var error: String? = nil
    var options: [VoteOption] = []
    var selectedChoice: String? = nil
    var hasVoted: Bool = false
    var myChoice: String? = nil
    var votedCount: Int = 0
    var totalPlayers: Int = 0
    var progress: Double = 0.0
    var showResults: Bool = false
    var percentages: [String: Double] = [:]
    var playerVotes: [PlayerVote] = []
    var voteSubmitted: Bool = false
    var currentRound: Int = 1
}

/// 投票 ViewModel
/// 管理投票選項載入、提交投票、追蹤進度和結果顯示
@MainActor
final class VotingViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var uiState = VoteUiState()

    // MARK: - Dependencies

    private let apiService: APIService
    private var refreshTask: Task<Void, Never>?

    // MARK: - Initialization

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    /// 載入投票資料（選項、進度、已投票狀態）
    func loadVoteData(roomCode: String, playerId: String, voteRound: Int) {
        Task {
            await performLoadVoteData(roomCode: roomCode, playerId: playerId, voteRound: voteRound)
        }
    }

    /// 選擇投票選項
    func selectOption(_ optionId: String) {
        guard !uiState.hasVoted else { return }
        uiState.selectedChoice = optionId
    }

    /// 提交投票
    func submitVote(roomCode: String, playerId: String, voteRound: Int) {
        guard let choice = uiState.selectedChoice else { return }

        Task {
            await performSubmitVote(
                roomCode: roomCode,
                playerId: playerId,
                voteRound: voteRound,
                choice: choice
            )
        }
    }

    /// 開始自動刷新投票進度
    func startAutoRefresh(roomCode: String, playerId: String, voteRound: Int, interval: TimeInterval = 3.0) {
        stopAutoRefresh()

        refreshTask = Task {
            while !Task.isCancelled {
                await refreshProgress(roomCode: roomCode, voteRound: voteRound)

                // 如果投票已完成，載入結果並停止刷新
                if uiState.showResults {
                    break
                }

                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    /// 停止自動刷新
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// 手動刷新投票進度
    func refreshProgress(roomCode: String, voteRound: Int) async {
        do {
            let progress = try await apiService.getVoteProgress(roomCode: roomCode, round: voteRound)

            uiState.votedCount = progress.votedCount
            uiState.totalPlayers = progress.totalPlayers
            uiState.progress = progress.progress

            let isComplete = progress.isComplete ?? (progress.progress >= 1.0)
            if isComplete && !uiState.showResults {
                await loadResults(roomCode: roomCode, voteRound: voteRound)
            }
        } catch {
            print("[VotingVM] Failed to refresh progress: \(error)")
        }
    }

    /// 載入投票結果
    func loadResults(roomCode: String, voteRound: Int) async {
        do {
            let result = try await apiService.getVoteResult(roomCode: roomCode, round: voteRound)

            uiState.showResults = true
            uiState.percentages = result.percentages
            uiState.playerVotes = result.votes ?? []
        } catch {
            print("[VotingVM] Failed to load results: \(error)")
        }
    }

    /// 清除錯誤
    func clearError() {
        uiState.error = nil
    }

    /// 重置狀態（切換投票輪次時使用）
    func reset() {
        stopAutoRefresh()
        uiState = VoteUiState()
    }

    /// 設定當前投票輪次
    func setCurrentRound(_ round: Int) {
        uiState.currentRound = round
    }

    // MARK: - Private Methods

    private func performLoadVoteData(roomCode: String, playerId: String, voteRound: Int) async {
        uiState.isLoading = true
        uiState.error = nil
        uiState.currentRound = voteRound

        do {
            // 並行載入：選項、進度、我的投票
            async let optionsTask = apiService.getVoteOptions(roomCode: roomCode)
            async let progressTask = apiService.getVoteProgress(roomCode: roomCode, round: voteRound)
            async let myVoteTask = apiService.getMyVote(roomCode: roomCode, playerId: playerId, round: voteRound)

            let (options, progress, myVote) = try await (optionsTask, progressTask, myVoteTask)

            uiState.options = options
            uiState.votedCount = progress.votedCount
            uiState.totalPlayers = progress.totalPlayers
            uiState.progress = progress.progress
            uiState.hasVoted = myVote.hasVoted
            uiState.myChoice = myVote.vote?.choice

            let isComplete = progress.isComplete ?? (progress.progress >= 1.0)
            uiState.showResults = isComplete

            // 如果投票已完成，載入結果
            if isComplete {
                await loadResults(roomCode: roomCode, voteRound: voteRound)
            }

            uiState.isLoading = false

        } catch {
            uiState.isLoading = false
            uiState.error = "載入失敗：\(error.localizedDescription)"
            print("[VotingVM] Load error: \(error)")
        }
    }

    private func performSubmitVote(roomCode: String, playerId: String, voteRound: Int, choice: String) async {
        uiState.isLoading = true
        uiState.error = nil

        do {
            _ = try await apiService.castVote(
                roomCode: roomCode,
                playerId: playerId,
                round: voteRound,
                choice: choice
            )

            uiState.isLoading = false
            uiState.hasVoted = true
            uiState.myChoice = choice
            uiState.voteSubmitted = true

            print("[VotingVM] Vote submitted: \(choice)")

        } catch {
            uiState.isLoading = false
            uiState.error = "投票失敗：\(error.localizedDescription)"
            print("[VotingVM] Submit error: \(error)")
        }
    }
}

// MARK: - Convenience Extensions

extension VotingViewModel {
    /// 取得選項的投票百分比
    func percentage(for optionId: String) -> Double {
        uiState.percentages[optionId] ?? 0.0
    }

    /// 檢查選項是否為目前選擇
    func isSelected(_ optionId: String) -> Bool {
        uiState.selectedChoice == optionId
    }

    /// 檢查選項是否為我的投票
    func isMyVote(_ optionId: String) -> Bool {
        uiState.myChoice == optionId
    }

    /// 取得投票進度文字
    var progressText: String {
        "\(uiState.votedCount)/\(uiState.totalPlayers) 人已投票"
    }

    /// 是否可以提交投票
    var canSubmit: Bool {
        !uiState.hasVoted && uiState.selectedChoice != nil && !uiState.isLoading
    }

    /// 投票輪次說明
    var roundDescription: String {
        switch uiState.currentRound {
        case 1: return "第一輪投票（匿名）"
        case 2: return "第二輪投票（記名）"
        default: return "第 \(uiState.currentRound) 輪投票"
        }
    }

    /// 是否為記名投票（第二輪）
    var isNamedVoting: Bool {
        uiState.currentRound == 2
    }
}
