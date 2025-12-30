import Foundation
import Combine

/// Host Panel UI 狀態
struct HostPanelUiState: Sendable {
    var isLoading: Bool = false
    var error: String? = nil
    var successMessage: String? = nil
    var currentPhase: Int = 1
    var timerEndAt: Date? = nil
    var playerCount: Int = 0
    var availableEvents: [EventData] = []
    var triggeredEvent: EventData? = nil
    var isChangingPhase: Bool = false
    var isSettingTimer: Bool = false
    var isTriggeringEvent: Bool = false
}

/// 主持人控制面板 ViewModel
/// 管理遊戲階段切換、計時器設定、突發事件觸發
@MainActor
final class HostPanelViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var uiState = HostPanelUiState()

    // MARK: - Dependencies

    private let apiService: APIService
    private var roomCode: String = ""
    private var playerId: String = ""

    // MARK: - Phase Names

    static let phaseNames: [Int: String] = [
        1: "等待中",
        2: "角色研究",
        3: "密謀時間",
        4: "開場陳述",
        5: "突發事件 #1",
        6: "自由辯論",
        7: "突發事件 #2",
        8: "第一輪投票",
        9: "最後攻防",
        10: "第二輪投票",
        11: "結果揭曉",
        12: "遊戲結束"
    ]

    // MARK: - Quick Phase Buttons

    static let quickPhases: [(phase: Int, label: String)] = [
        (2, "角色研究"),
        (3, "密謀"),
        (4, "辯論"),
        (8, "投票1"),
        (10, "投票2"),
        (11, "揭曉")
    ]

    // MARK: - Timer Options (minutes)

    static let timerOptions: [Int] = [5, 10, 15, 20, 25, 30]

    // MARK: - Initialization

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    // MARK: - Public Methods

    /// 初始化主持人面板
    func initialize(roomCode: String, playerId: String) {
        self.roomCode = roomCode
        self.playerId = playerId
        loadRoomData()
        loadAvailableEvents()
    }

    /// 載入房間資料
    func loadRoomData() {
        guard !roomCode.isEmpty else { return }

        Task {
            uiState.isLoading = true
            do {
                let room = try await apiService.getRoom(code: roomCode)
                let players = try await apiService.getPlayers(roomCode: roomCode)

                uiState.currentPhase = room.phase
                uiState.playerCount = players.count

                if let timerEndAtString = room.timerEndAt {
                    uiState.timerEndAt = ISO8601DateFormatter().date(from: timerEndAtString)
                } else {
                    uiState.timerEndAt = nil
                }

                uiState.isLoading = false
            } catch {
                uiState.isLoading = false
                uiState.error = "載入失敗：\(error.localizedDescription)"
            }
        }
    }

    /// 載入可用的突發事件
    func loadAvailableEvents() {
        guard !roomCode.isEmpty else { return }

        Task {
            do {
                let events = try await apiService.getAvailableEvents(roomCode: roomCode)
                uiState.availableEvents = events
            } catch {
                print("[HostPanelVM] Failed to load events: \(error)")
            }
        }
    }

    /// 切換遊戲階段
    func changePhase(to phase: Int) {
        guard !roomCode.isEmpty, !playerId.isEmpty else { return }
        guard phase >= 1 && phase <= 12 else { return }

        Task {
            uiState.isChangingPhase = true
            uiState.error = nil

            do {
                try await apiService.changePhase(roomCode: roomCode, phase: phase, playerId: playerId)
                uiState.currentPhase = phase
                uiState.successMessage = "已切換至 \(Self.phaseNames[phase] ?? "階段 \(phase)")"
                uiState.isChangingPhase = false
            } catch {
                uiState.isChangingPhase = false
                uiState.error = "切換階段失敗：\(error.localizedDescription)"
            }
        }
    }

    /// 設定計時器
    func setTimer(minutes: Int) {
        guard !roomCode.isEmpty, !playerId.isEmpty else { return }
        guard minutes > 0 else { return }

        Task {
            uiState.isSettingTimer = true
            uiState.error = nil

            do {
                let endAt = try await apiService.setTimer(roomCode: roomCode, minutes: minutes, playerId: playerId)
                uiState.timerEndAt = ISO8601DateFormatter().date(from: endAt)
                uiState.successMessage = "計時器已設定為 \(minutes) 分鐘"
                uiState.isSettingTimer = false
            } catch {
                uiState.isSettingTimer = false
                uiState.error = "設定計時器失敗：\(error.localizedDescription)"
            }
        }
    }

    /// 觸發指定事件
    func triggerEvent(_ event: EventData) {
        guard !roomCode.isEmpty, !playerId.isEmpty else { return }

        Task {
            uiState.isTriggeringEvent = true
            uiState.error = nil

            do {
                let triggeredEvent = try await apiService.triggerEvent(
                    roomCode: roomCode,
                    eventId: event.id,
                    playerId: playerId
                )
                uiState.triggeredEvent = triggeredEvent
                uiState.successMessage = "已觸發事件：\(triggeredEvent.title)"
                uiState.isTriggeringEvent = false
            } catch {
                uiState.isTriggeringEvent = false
                uiState.error = "觸發事件失敗：\(error.localizedDescription)"
            }
        }
    }

    /// 隨機觸發事件
    func triggerRandomEvent() {
        guard !roomCode.isEmpty, !playerId.isEmpty else { return }

        Task {
            uiState.isTriggeringEvent = true
            uiState.error = nil

            do {
                let triggeredEvent = try await apiService.triggerRandomEvent(
                    roomCode: roomCode,
                    playerId: playerId
                )
                uiState.triggeredEvent = triggeredEvent
                uiState.successMessage = "隨機事件：\(triggeredEvent.title)"
                uiState.isTriggeringEvent = false
            } catch {
                uiState.isTriggeringEvent = false
                uiState.error = "觸發隨機事件失敗：\(error.localizedDescription)"
            }
        }
    }

    /// 清除錯誤訊息
    func clearError() {
        uiState.error = nil
    }

    /// 清除成功訊息
    func clearSuccessMessage() {
        uiState.successMessage = nil
    }

    /// 清除觸發的事件
    func clearTriggeredEvent() {
        uiState.triggeredEvent = nil
    }

    /// 刷新資料
    func refreshData() {
        loadRoomData()
        loadAvailableEvents()
    }

    /// 前進到下一階段
    func nextPhase() {
        let nextPhase = min(uiState.currentPhase + 1, 12)
        changePhase(to: nextPhase)
    }

    /// 返回上一階段
    func previousPhase() {
        let prevPhase = max(uiState.currentPhase - 1, 1)
        changePhase(to: prevPhase)
    }
}

// MARK: - Convenience Extensions

extension HostPanelViewModel {
    /// 取得當前階段名稱
    var currentPhaseName: String {
        Self.phaseNames[uiState.currentPhase] ?? "未知階段"
    }

    /// 計時器是否正在運行
    var isTimerRunning: Bool {
        guard let endAt = uiState.timerEndAt else { return false }
        return endAt > Date()
    }

    /// 計時器剩餘秒數
    var timerRemainingSeconds: Int {
        guard let endAt = uiState.timerEndAt else { return 0 }
        let remaining = endAt.timeIntervalSinceNow
        return max(0, Int(remaining))
    }

    /// 格式化計時器剩餘時間
    var timerRemainingFormatted: String {
        let seconds = timerRemainingSeconds
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    /// 是否可以前進到下一階段
    var canGoNext: Bool {
        uiState.currentPhase < 12 && !uiState.isChangingPhase
    }

    /// 是否可以返回上一階段
    var canGoPrevious: Bool {
        uiState.currentPhase > 1 && !uiState.isChangingPhase
    }

    /// 是否正在執行任何操作
    var isBusy: Bool {
        uiState.isLoading || uiState.isChangingPhase || uiState.isSettingTimer || uiState.isTriggeringEvent
    }
}
