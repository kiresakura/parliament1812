package com.parliament1812.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.remote.WebSocketEvent
import com.parliament1812.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CurrentEvent(
    val id: String,
    val title: String,
    val description: String,
    val effectType: String
)

data class GameUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val roomCode: String = "",
    val playerId: String = "",
    val phase: Int = 1,
    val currentRound: Int = 0,
    val timerEndAt: Long? = null,
    val players: List<PlayerBrief> = emptyList(),
    val myRoleType: String? = null,
    val myRoleName: String? = null,
    val myRoleOccupation: String? = null,
    val unreadCount: Int = 0,
    val currentEvent: CurrentEvent? = null,
    val hasVotedRound1: Boolean = false,
    val hasVotedRound2: Boolean = false
)

@HiltViewModel
class GameViewModel @Inject constructor(
    private val apiService: ApiService,
    private val webSocketService: WebSocketService
) : ViewModel() {

    private val _uiState = MutableStateFlow(GameUiState())
    val uiState: StateFlow<GameUiState> = _uiState.asStateFlow()

    fun loadRoomData(roomCode: String, playerId: String) {
        _uiState.update { it.copy(roomCode = roomCode, playerId = playerId, isLoading = true) }

        viewModelScope.launch {
            try {
                // Load room details
                val room = apiService.getRoomDetail(roomCode)

                // Find my player info
                val myPlayer = room.players.find { it.id == playerId }

                // Parse timer
                val timerEndAt = room.timerEndAt?.let {
                    try {
                        java.time.Instant.parse(it).toEpochMilli()
                    } catch (e: Exception) {
                        null
                    }
                }

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        phase = room.phase,
                        currentRound = room.currentRound,
                        timerEndAt = timerEndAt,
                        players = room.players,
                        myRoleType = myPlayer?.roleType
                    )
                }

                // Load role details if assigned
                myPlayer?.roleType?.let { roleType ->
                    loadRoleDetails(roleType)
                }

                // Load unread message count
                loadUnreadCount(roomCode, playerId)

                // Load event history
                loadCurrentEvent(roomCode)

                // Check vote status
                checkVoteStatus(roomCode, playerId)

                // Connect to WebSocket
                connectWebSocket(roomCode, playerId)

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入失敗：${e.message}")
                }
            }
        }
    }

    private suspend fun loadRoleDetails(roleType: String) {
        try {
            val role = apiService.getRole(roleType)
            _uiState.update {
                it.copy(
                    myRoleName = role.nameZh,
                    myRoleOccupation = role.faction
                )
            }
        } catch (e: Exception) {
            // Non-critical, just log
        }
    }

    private suspend fun loadUnreadCount(roomCode: String, playerId: String) {
        try {
            val response = apiService.getUnreadCount(playerId, roomCode)
            _uiState.update { it.copy(unreadCount = response.unreadCount) }
        } catch (e: Exception) {
            // Non-critical
        }
    }

    private suspend fun loadCurrentEvent(roomCode: String) {
        try {
            val events = apiService.getEventHistory(roomCode)
            events.lastOrNull()?.let { event ->
                _uiState.update {
                    it.copy(
                        currentEvent = CurrentEvent(
                            id = event.event.id,
                            title = event.event.title,
                            description = event.event.description,
                            effectType = event.event.effectType
                        )
                    )
                }
            }
        } catch (e: Exception) {
            // Non-critical
        }
    }

    private suspend fun checkVoteStatus(roomCode: String, playerId: String) {
        try {
            val vote1 = apiService.getMyVote(roomCode, playerId, 1)
            val vote2 = apiService.getMyVote(roomCode, playerId, 2)
            _uiState.update {
                it.copy(
                    hasVotedRound1 = vote1.hasVoted,
                    hasVotedRound2 = vote2.hasVoted
                )
            }
        } catch (e: Exception) {
            // Non-critical
        }
    }

    private fun connectWebSocket(roomCode: String, playerId: String) {
        viewModelScope.launch {
            webSocketService.connect(roomCode, playerId)

            // Listen to WebSocket events
            webSocketService.events.collect { event ->
                handleWebSocketEvent(event)
            }
        }
    }

    private fun handleWebSocketEvent(event: WebSocketEvent) {
        when (event) {
            is WebSocketEvent.GenericMessage -> {
                when (event.type) {
                    "phase_change" -> {
                        event.data?.get("phase")?.toIntOrNull()?.let { phase ->
                            _uiState.update { it.copy(phase = phase) }
                        }
                    }
                    "timer_sync" -> {
                        event.data?.get("end_at")?.let { endAt ->
                            try {
                                val millis = java.time.Instant.parse(endAt).toEpochMilli()
                                _uiState.update { it.copy(timerEndAt = millis) }
                            } catch (e: Exception) {
                                // Ignore parse errors
                            }
                        }
                    }
                    "private_message" -> {
                        // Increment unread count
                        _uiState.update { it.copy(unreadCount = it.unreadCount + 1) }
                    }
                    "event_trigger" -> {
                        // Update current event
                        val title = event.data?.get("title") ?: ""
                        val description = event.data?.get("description") ?: ""
                        val eventId = event.data?.get("event_id") ?: ""
                        val effectType = event.data?.get("effect_type") ?: ""

                        _uiState.update {
                            it.copy(
                                currentEvent = CurrentEvent(
                                    id = eventId,
                                    title = title,
                                    description = description,
                                    effectType = effectType
                                )
                            )
                        }
                    }
                    "vote_update", "vote_result" -> {
                        // Could refresh vote status here
                    }
                }
            }
            is WebSocketEvent.PlayerJoined, is WebSocketEvent.PlayerLeft -> {
                // Reload players list
                viewModelScope.launch {
                    try {
                        val room = apiService.getRoomDetail(_uiState.value.roomCode)
                        _uiState.update { it.copy(players = room.players) }
                    } catch (e: Exception) {
                        // Ignore
                    }
                }
            }
            is WebSocketEvent.Error -> {
                _uiState.update { it.copy(error = event.message) }
            }
            else -> { /* Ignore other events */ }
        }
    }

    fun refreshData() {
        val roomCode = _uiState.value.roomCode
        val playerId = _uiState.value.playerId
        if (roomCode.isNotEmpty() && playerId.isNotEmpty()) {
            loadRoomData(roomCode, playerId)
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    override fun onCleared() {
        super.onCleared()
        viewModelScope.launch {
            webSocketService.disconnect()
        }
    }
}
