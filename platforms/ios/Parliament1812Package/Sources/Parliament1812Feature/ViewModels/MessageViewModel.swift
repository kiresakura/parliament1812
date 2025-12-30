import Foundation
import SwiftUI

// MARK: - Message UI State
struct MessageUiState: Equatable {
    var conversations: [Conversation] = []
    var messages: [MessageResponse] = []
    var selectedPlayerId: String? = nil
    var messageInput: String = ""
    var isLoading: Bool = false
    var isSending: Bool = false
    var error: String? = nil
    var totalUnread: Int = 0
}

// MARK: - Message ViewModel
@MainActor
final class MessageViewModel: ObservableObject {
    @Published private(set) var uiState = MessageUiState()

    private let apiService: APIService
    private var refreshTask: Task<Void, Never>?
    private var currentRoomCode: String?
    private var currentPlayerId: String?

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Public Methods

    /// 載入對話列表
    func loadConversations(roomCode: String, playerId: String) async {
        currentRoomCode = roomCode
        currentPlayerId = playerId

        uiState.isLoading = true
        uiState.error = nil

        do {
            let response = try await apiService.getConversations(
                roomCode: roomCode,
                playerId: playerId
            )
            uiState.conversations = response.conversations
            uiState.totalUnread = response.conversations.reduce(0) { $0 + $1.unreadCount }
            uiState.isLoading = false

            // Start auto-refresh
            startAutoRefresh()
        } catch {
            uiState.error = "載入對話失敗: \(error.localizedDescription)"
            uiState.isLoading = false
        }
    }

    /// 載入與特定玩家的訊息
    func loadMessages(roomCode: String, playerId: String, otherPlayerId: String) async {
        uiState.isLoading = true
        uiState.error = nil
        uiState.selectedPlayerId = otherPlayerId

        do {
            let response = try await apiService.getMessages(
                roomCode: roomCode,
                playerId: playerId,
                otherPlayerId: otherPlayerId
            )
            uiState.messages = response.messages
            uiState.isLoading = false

            // Auto mark as read when loading messages
            await markAsRead(playerId: playerId, senderId: otherPlayerId)
        } catch {
            uiState.error = "載入訊息失敗: \(error.localizedDescription)"
            uiState.isLoading = false
        }
    }

    /// 發送訊息
    func sendMessage(roomCode: String, senderId: String, receiverId: String) async {
        let content = uiState.messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        uiState.isSending = true
        uiState.error = nil

        do {
            let message = try await apiService.sendMessage(
                roomCode: roomCode,
                senderId: senderId,
                receiverId: receiverId,
                content: content
            )

            // Add the new message to the list
            uiState.messages.append(message)
            uiState.messageInput = ""
            uiState.isSending = false

            // Refresh conversations to update last message
            await loadConversations(roomCode: roomCode, playerId: senderId)
        } catch {
            uiState.error = "發送訊息失敗: \(error.localizedDescription)"
            uiState.isSending = false
        }
    }

    /// 標記訊息為已讀
    func markAsRead(playerId: String, senderId: String) async {
        do {
            _ = try await apiService.markMessagesAsRead(
                playerId: playerId,
                senderId: senderId
            )

            // Update local unread count
            if let index = uiState.conversations.firstIndex(where: { $0.playerId == senderId }) {
                uiState.totalUnread -= uiState.conversations[index].unreadCount
                uiState.conversations[index] = Conversation(
                    playerId: uiState.conversations[index].playerId,
                    nickname: uiState.conversations[index].nickname,
                    lastMessage: uiState.conversations[index].lastMessage,
                    lastMessageAt: uiState.conversations[index].lastMessageAt,
                    unreadCount: 0
                )
            }
        } catch {
            // Silent fail for mark as read
            print("Failed to mark messages as read: \(error)")
        }
    }

    /// 刷新未讀數量
    func refreshUnreadCount(roomCode: String, playerId: String) async {
        do {
            let response = try await apiService.getConversations(
                roomCode: roomCode,
                playerId: playerId
            )
            uiState.totalUnread = response.conversations.reduce(0) { $0 + $1.unreadCount }
            uiState.conversations = response.conversations
        } catch {
            // Silent fail for refresh
            print("Failed to refresh unread count: \(error)")
        }
    }

    /// 更新訊息輸入
    func updateMessageInput(_ text: String) {
        uiState.messageInput = text
    }

    /// 選擇對話
    func selectConversation(_ playerId: String?) {
        uiState.selectedPlayerId = playerId
        if playerId == nil {
            uiState.messages = []
        }
    }

    /// 清除錯誤
    func clearError() {
        uiState.error = nil
    }

    // MARK: - Private Methods

    private func startAutoRefresh() {
        refreshTask?.cancel()

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                guard !Task.isCancelled,
                      let self = self,
                      let roomCode = self.currentRoomCode,
                      let playerId = self.currentPlayerId else {
                    break
                }

                await self.refreshUnreadCount(roomCode: roomCode, playerId: playerId)

                // Also refresh current conversation if one is selected
                if let selectedId = self.uiState.selectedPlayerId {
                    await self.refreshMessages(roomCode: roomCode, playerId: playerId, otherPlayerId: selectedId)
                }
            }
        }
    }

    private func refreshMessages(roomCode: String, playerId: String, otherPlayerId: String) async {
        do {
            let response = try await apiService.getMessages(
                roomCode: roomCode,
                playerId: playerId,
                otherPlayerId: otherPlayerId
            )

            // Only update if we have new messages
            if response.messages.count != uiState.messages.count {
                uiState.messages = response.messages
            }
        } catch {
            // Silent fail for refresh
            print("Failed to refresh messages: \(error)")
        }
    }

    /// 停止自動刷新
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
