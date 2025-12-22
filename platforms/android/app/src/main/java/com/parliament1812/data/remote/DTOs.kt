package com.parliament1812.data.remote

import com.parliament1812.data.models.Player
import com.parliament1812.data.models.Role
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

// ========== Room Request DTOs ==========

@Serializable
data class CreateRoomRequest(
    @SerialName("host_nickname") val hostNickname: String
)

@Serializable
data class JoinRoomRequest(
    val nickname: String
)

@Serializable
data class PhaseChangeRequest(
    val phase: Int
)

@Serializable
data class TimerRequest(
    @SerialName("duration_seconds") val durationSeconds: Int
)

// ========== NFC Request DTOs ==========

@Serializable
data class NFCScanRequest(
    @SerialName("room_code") val roomCode: String,
    @SerialName("player_id") val playerId: String,
    @SerialName("card_id") val cardId: String,
    val signature: String
)

@Serializable
data class ManualRoleRequest(
    @SerialName("player_id") val playerId: String,
    @SerialName("role_code") val roleCode: String
)

// ========== Message Request DTOs ==========

@Serializable
data class SendMessageRequest(
    @SerialName("receiver_id") val receiverId: String,
    val content: String
)

@Serializable
data class MarkReadRequest(
    @SerialName("message_ids") val messageIds: List<String>? = null
)

// ========== Vote Request DTOs ==========

@Serializable
data class VoteRequest(
    val choice: String
)

// ========== Event Request DTOs ==========

@Serializable
data class TriggerEventRequest(
    @SerialName("event_id") val eventId: String
)

// ========== Room Response DTOs ==========

@Serializable
data class CreateRoomResponse(
    val code: String,
    @SerialName("room_id") val roomId: String,
    @SerialName("player_id") val playerId: String,
    val message: String? = null
)

@Serializable
data class JoinRoomResponse(
    @SerialName("player_id") val playerId: String,
    @SerialName("room_code") val roomCode: String,
    val message: String? = null
)

@Serializable
data class RoomDetailResponse(
    val id: String,
    val code: String,
    val status: String,
    val phase: Int,
    @SerialName("current_round") val currentRound: Int,
    @SerialName("timer_end_at") val timerEndAt: String? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("player_count") val playerCount: Int,
    val players: List<PlayerBrief> = emptyList()
)

@Serializable
data class PlayerBrief(
    val id: String,
    val nickname: String,
    @SerialName("role_type") val roleType: String? = null,
    @SerialName("is_host") val isHost: Boolean
)

// ========== NFC Response DTOs ==========

@Serializable
data class NFCScanResponse(
    val success: Boolean,
    @SerialName("role_type") val roleType: String? = null,
    @SerialName("role_index") val roleIndex: Int? = null,
    @SerialName("secret_mission_id") val secretMissionId: String? = null,
    val role: Role? = null,
    val message: String? = null
)

@Serializable
data class ManualRoleResponse(
    val message: String,
    @SerialName("player_id") val playerId: String,
    @SerialName("role_type") val roleType: String,
    @SerialName("role_index") val roleIndex: Int,
    @SerialName("role_name") val roleName: String,
    @SerialName("role_occupation") val roleOccupation: String,
    @SerialName("role_description") val roleDescription: String,
    @SerialName("role_background") val roleBackground: String,
    @SerialName("role_public_stance") val rolePublicStance: String,
    @SerialName("avatar_color") val avatarColor: String,
    @SerialName("secret_mission_id") val secretMissionId: String
)

// ========== Message Response DTOs ==========

@Serializable
data class MessageResponse(
    val id: String,
    @SerialName("sender_id") val senderId: String,
    @SerialName("sender_nickname") val senderNickname: String,
    @SerialName("receiver_id") val receiverId: String,
    @SerialName("receiver_nickname") val receiverNickname: String,
    val content: String,
    @SerialName("is_read") val isRead: Boolean,
    @SerialName("sent_at") val sentAt: String
)

@Serializable
data class MessageListResponse(
    val messages: List<MessageResponse>,
    val total: Int,
    @SerialName("unread_count") val unreadCount: Int
)

@Serializable
data class ConversationInfo(
    @SerialName("player_id") val playerId: String,
    val nickname: String,
    @SerialName("last_message") val lastMessage: String,
    @SerialName("last_message_at") val lastMessageAt: String,
    @SerialName("unread_count") val unreadCount: Int
)

@Serializable
data class ConversationsResponse(
    val conversations: List<ConversationInfo>,
    @SerialName("total_unread") val totalUnread: Int
)

@Serializable
data class UnreadCountResponse(
    @SerialName("unread_count") val unreadCount: Int
)

// ========== Vote Response DTOs ==========

@Serializable
data class VoteResponse(
    val id: String,
    @SerialName("player_id") val playerId: String,
    val round: Int,
    val choice: String,
    @SerialName("voted_at") val votedAt: String
)

@Serializable
data class VoteProgressResponse(
    val round: Int,
    @SerialName("voted_count") val votedCount: Int,
    @SerialName("total_players") val totalPlayers: Int,
    val progress: Float,
    @SerialName("is_complete") val isComplete: Boolean = false
)

@Serializable
data class VoteResultRound1(
    val round: Int = 1,
    @SerialName("total_votes") val totalVotes: Int,
    val percentages: Map<String, Float>,
    @SerialName("is_complete") val isComplete: Boolean
)

@Serializable
data class VoteResultRound2(
    val round: Int = 2,
    @SerialName("total_votes") val totalVotes: Int,
    val votes: List<PlayerVote>,
    val results: Map<String, Int>,
    val winner: String?,
    @SerialName("is_complete") val isComplete: Boolean
)

@Serializable
data class PlayerVote(
    @SerialName("player_id") val playerId: String,
    val nickname: String,
    @SerialName("role_type") val roleType: String?,
    val choice: String
)

@Serializable
data class VoteOption(
    val key: String,
    val title: String,
    val description: String,
    @SerialName("is_hidden") val isHidden: Boolean = false
)

@Serializable
data class MyVoteResponse(
    @SerialName("has_voted") val hasVoted: Boolean,
    val vote: VoteDetail? = null
)

@Serializable
data class VoteDetail(
    val id: String,
    val round: Int,
    val choice: String,
    @SerialName("voted_at") val votedAt: String
)

// ========== Event Response DTOs ==========

@Serializable
data class EventResponse(
    val id: String,
    val title: String,
    val description: String,
    @SerialName("effect_type") val effectType: String,
    val severity: Int
)

@Serializable
data class GameEventResponse(
    val id: String,
    val event: EventResponse,
    @SerialName("triggered_at") val triggeredAt: String
)

// ========== WebSocket Events ==========

@Serializable
data class WebSocketMessage(
    val type: String,
    val data: Map<String, String>? = null
)

@Serializable
data class WSPlayerJoinData(
    val player: PlayerBrief
)

@Serializable
data class WSPhaseChangeData(
    val phase: Int,
    @SerialName("phase_name") val phaseName: String
)

@Serializable
data class WSTimerSyncData(
    @SerialName("end_at") val endAt: String
)

@Serializable
data class WSPrivateMessageData(
    @SerialName("message_id") val messageId: String,
    @SerialName("from_id") val fromId: String,
    @SerialName("from_nickname") val fromNickname: String,
    val content: String,
    @SerialName("sent_at") val sentAt: String
)

@Serializable
data class WSEventTriggerData(
    @SerialName("event_id") val eventId: String,
    val title: String,
    val description: String,
    @SerialName("effect_type") val effectType: String
)

@Serializable
data class WSVoteUpdateData(
    val round: Int,
    val progress: Float,
    @SerialName("is_complete") val isComplete: Boolean
)
