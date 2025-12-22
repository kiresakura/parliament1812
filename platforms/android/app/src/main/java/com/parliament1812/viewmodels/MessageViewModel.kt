package com.parliament1812.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ConversationPreview(
    val playerId: String,
    val nickname: String,
    val lastMessage: String,
    val lastMessageAt: String,
    val unreadCount: Int
)

data class ChatMessage(
    val id: String,
    val senderId: String,
    val senderNickname: String,
    val content: String,
    val sentAt: String,
    val isFromMe: Boolean
)

data class MessageUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val conversations: List<ConversationPreview> = emptyList(),
    val totalUnread: Int = 0,
    val availablePlayers: List<PlayerBrief> = emptyList(),
    // Chat state
    val currentChatPlayerId: String? = null,
    val currentChatNickname: String = "",
    val messages: List<ChatMessage> = emptyList(),
    val messageInput: String = "",
    val isSending: Boolean = false
)

@HiltViewModel
class MessageViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(MessageUiState())
    val uiState: StateFlow<MessageUiState> = _uiState.asStateFlow()

    private var roomCode: String = ""
    private var myPlayerId: String = ""

    fun initialize(roomCode: String, playerId: String) {
        this.roomCode = roomCode
        this.myPlayerId = playerId
        loadConversations()
        loadAvailablePlayers()
    }

    private fun loadConversations() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val response = apiService.getConversations(myPlayerId, roomCode)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        conversations = response.conversations.map { conv ->
                            ConversationPreview(
                                playerId = conv.playerId,
                                nickname = conv.nickname,
                                lastMessage = conv.lastMessage,
                                lastMessageAt = conv.lastMessageAt,
                                unreadCount = conv.unreadCount
                            )
                        },
                        totalUnread = response.totalUnread
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入對話失敗：${e.message}")
                }
            }
        }
    }

    private fun loadAvailablePlayers() {
        viewModelScope.launch {
            try {
                val room = apiService.getRoomDetail(roomCode)
                val otherPlayers = room.players.filter { it.id != myPlayerId }
                _uiState.update { it.copy(availablePlayers = otherPlayers) }
            } catch (e: Exception) {
                // Non-critical
            }
        }
    }

    fun openChat(playerId: String, nickname: String) {
        _uiState.update {
            it.copy(
                currentChatPlayerId = playerId,
                currentChatNickname = nickname,
                messages = emptyList()
            )
        }
        loadMessages(playerId)
    }

    fun closeChat() {
        _uiState.update {
            it.copy(
                currentChatPlayerId = null,
                currentChatNickname = "",
                messages = emptyList(),
                messageInput = ""
            )
        }
        loadConversations() // Refresh conversations list
    }

    private fun loadMessages(otherPlayerId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val response = apiService.getMessages(
                    playerId = myPlayerId,
                    roomCode = roomCode,
                    otherPlayerId = otherPlayerId
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        messages = response.messages.map { msg ->
                            ChatMessage(
                                id = msg.id,
                                senderId = msg.senderId,
                                senderNickname = msg.senderNickname,
                                content = msg.content,
                                sentAt = msg.sentAt,
                                isFromMe = msg.senderId == myPlayerId
                            )
                        }.reversed() // Show oldest first
                    )
                }

                // Mark as read
                markMessagesAsRead(otherPlayerId)

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入訊息失敗：${e.message}")
                }
            }
        }
    }

    private fun markMessagesAsRead(senderId: String) {
        viewModelScope.launch {
            try {
                apiService.markAsRead(
                    playerId = myPlayerId,
                    senderId = senderId,
                    request = MarkReadRequest()
                )
            } catch (e: Exception) {
                // Non-critical
            }
        }
    }

    fun updateMessageInput(text: String) {
        _uiState.update { it.copy(messageInput = text) }
    }

    fun sendMessage() {
        val content = _uiState.value.messageInput.trim()
        val receiverId = _uiState.value.currentChatPlayerId
        if (content.isEmpty() || receiverId == null) return

        viewModelScope.launch {
            _uiState.update { it.copy(isSending = true) }
            try {
                val response = apiService.sendMessage(
                    senderId = myPlayerId,
                    roomCode = roomCode,
                    request = SendMessageRequest(
                        receiverId = receiverId,
                        content = content
                    )
                )

                // Add message to list
                val newMessage = ChatMessage(
                    id = response.id,
                    senderId = response.senderId,
                    senderNickname = response.senderNickname,
                    content = response.content,
                    sentAt = response.sentAt,
                    isFromMe = true
                )

                _uiState.update {
                    it.copy(
                        isSending = false,
                        messageInput = "",
                        messages = it.messages + newMessage
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isSending = false, error = "發送失敗：${e.message}")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun refreshMessages() {
        _uiState.value.currentChatPlayerId?.let { loadMessages(it) }
    }
}
