package com.parliament1812.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.models.*
import com.parliament1812.data.remote.WebSocketEvent
import com.parliament1812.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

// Dice roll state for international events
data class DiceRollState(
    val value: Int = 0,
    val threshold: Int = 4,
    val triggered: Boolean = false,
    val isVisible: Boolean = false
)

// Vote progress state
data class VoteProgressState(
    val round: Int = 0,
    val votedCount: Int = 0,
    val totalPlayers: Int = 0,
    val progress: Double = 0.0,
    val isAnonymous: Boolean = true,
    val isActive: Boolean = false,
    val winningChoice: String? = null
)

data class GameUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val roomCode: String = "",
    val playerId: String = "",
    val phase: Int = 1,
    val currentRound: Int = 0,
    val timerEndAt: Long? = null,
    val timerDuration: Int = 0,
    val players: List<PlayerBrief> = emptyList(),
    val myRoleType: String? = null,
    val myRoleName: String? = null,
    val myRoleOccupation: String? = null,
    val unreadCount: Int = 0,
    val currentEvent: GameEventData? = null,
    val selectedEventChoice: EventChoice? = null,
    val hasVotedRound1: Boolean = false,
    val hasVotedRound2: Boolean = false,
    // Auto Game Flow States
    val diceRoll: DiceRollState = DiceRollState(),
    val voteProgress: VoteProgressState = VoteProgressState(),
    val showFinalResults: Boolean = false
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
                // Try to find a predefined event first, otherwise create from server data
                val gameEvent = EventRepository.allEvents.find { it.id == event.event.id }
                    ?: GameEventData(
                        id = event.event.id,
                        title = event.event.title,
                        englishTitle = event.event.title,
                        description = event.event.description,
                        category = EventCategory.DOMESTIC,
                        type = EventType.fromString(event.event.effectType),
                        severity = 2,
                        effects = emptyList(),
                        choices = null
                    )

                _uiState.update { it.copy(currentEvent = gameEvent) }
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
            // Auto Game Flow Events
            is WebSocketEvent.PhaseChanged -> {
                _uiState.update { state ->
                    state.copy(
                        phase = event.phase,
                        // Reset dice roll when phase changes (except event2)
                        diceRoll = if (event.phase != 7) DiceRollState() else state.diceRoll
                    )
                }
            }

            is WebSocketEvent.TimerSync -> {
                _uiState.update {
                    it.copy(timerEndAt = event.endAt, timerDuration = event.duration)
                }
            }

            is WebSocketEvent.DiceRoll -> {
                _uiState.update {
                    it.copy(
                        diceRoll = DiceRollState(
                            value = event.value,
                            threshold = event.threshold,
                            triggered = event.triggered,
                            isVisible = true
                        )
                    )
                }
            }

            is WebSocketEvent.VoteStart -> {
                _uiState.update {
                    it.copy(
                        voteProgress = VoteProgressState(
                            round = event.round,
                            isAnonymous = event.isAnonymous,
                            isActive = true,
                            totalPlayers = it.players.size
                        )
                    )
                }
            }

            is WebSocketEvent.VoteUpdate -> {
                _uiState.update { state ->
                    state.copy(
                        voteProgress = state.voteProgress.copy(
                            votedCount = event.votedCount,
                            totalPlayers = event.totalPlayers,
                            progress = event.progress
                        )
                    )
                }
            }

            is WebSocketEvent.VoteResult -> {
                _uiState.update { state ->
                    state.copy(
                        voteProgress = state.voteProgress.copy(
                            isActive = false,
                            winningChoice = event.winningChoice
                        )
                    )
                }
            }

            is WebSocketEvent.EventTrigger -> {
                // Try to find a predefined event first
                val gameEvent = EventRepository.allEvents.find { it.id == event.eventId }
                    ?: GameEventData(
                        id = event.eventId,
                        title = event.title,
                        englishTitle = event.title,
                        description = event.description,
                        category = EventCategory.DOMESTIC,
                        type = EventType.fromString(event.effectType ?: ""),
                        severity = 2,
                        effects = emptyList(),
                        choices = null
                    )

                _uiState.update {
                    it.copy(currentEvent = gameEvent, selectedEventChoice = null)
                }
            }

            is WebSocketEvent.FinalResults -> {
                _uiState.update {
                    it.copy(showFinalResults = true)
                }
            }

            is WebSocketEvent.GenericMessage -> {
                when (event.type) {
                    "private_message" -> {
                        // Increment unread count
                        _uiState.update { it.copy(unreadCount = it.unreadCount + 1) }
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

    fun selectEventChoice(choice: EventChoice) {
        _uiState.update { it.copy(selectedEventChoice = choice) }
    }

    fun submitEventChoice() {
        val currentEvent = _uiState.value.currentEvent ?: return
        val selectedChoice = _uiState.value.selectedEventChoice ?: return
        val roomCode = _uiState.value.roomCode

        viewModelScope.launch {
            try {
                // Send event choice via WebSocket
                webSocketService.sendEventChoice(
                    eventId = currentEvent.id,
                    choiceId = selectedChoice.id
                )
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "提交選擇失敗：${e.message}") }
            }
        }
    }

    fun clearCurrentEvent() {
        _uiState.update { it.copy(currentEvent = null, selectedEventChoice = null) }
    }

    fun dismissDiceRoll() {
        _uiState.update { it.copy(diceRoll = DiceRollState()) }
    }

    fun dismissVoteProgress() {
        _uiState.update {
            it.copy(voteProgress = VoteProgressState())
        }
    }

    override fun onCleared() {
        super.onCleared()
        viewModelScope.launch {
            webSocketService.disconnect()
        }
    }
}
