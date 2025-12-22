package com.parliament1812.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.models.Player
import com.parliament1812.data.remote.ApiService
import com.parliament1812.data.remote.CreateRoomRequest
import com.parliament1812.data.remote.JoinRoomRequest
import com.parliament1812.data.remote.WebSocketEvent
import com.parliament1812.data.remote.WebSocketService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class RoomUiState(
    val isLoading: Boolean = false,
    val roomCode: String? = null,
    val currentPlayer: Player? = null,
    val players: List<Player> = emptyList(),
    val error: String? = null,
    val isHost: Boolean = false
)

@HiltViewModel
class RoomViewModel @Inject constructor(
    private val apiService: ApiService,
    private val webSocketService: WebSocketService
) : ViewModel() {

    private val _uiState = MutableStateFlow(RoomUiState())
    val uiState: StateFlow<RoomUiState> = _uiState.asStateFlow()

    companion object {
        private const val TAG = "RoomViewModel"
    }

    init {
        observeWebSocketEvents()
    }

    private fun observeWebSocketEvents() {
        viewModelScope.launch {
            webSocketService.events.collect { event ->
                when (event) {
                    is WebSocketEvent.PlayerJoined -> {
                        Log.d(TAG, "Player joined: ${event.player.nickname}")
                        _uiState.update { state ->
                            val updatedPlayers = state.players.toMutableList()
                            if (!updatedPlayers.any { it.id == event.player.id }) {
                                updatedPlayers.add(event.player)
                            }
                            state.copy(players = updatedPlayers)
                        }
                    }

                    is WebSocketEvent.PlayerLeft -> {
                        Log.d(TAG, "Player left: ${event.playerId}")
                        _uiState.update { state ->
                            state.copy(
                                players = state.players.filter { it.id != event.playerId }
                            )
                        }
                    }

                    is WebSocketEvent.RoleAssigned -> {
                        Log.d(TAG, "Role assigned: ${event.playerId} -> ${event.roleType}")
                        _uiState.update { state ->
                            val updatedPlayers = state.players.map { player ->
                                if (player.id == event.playerId) {
                                    player.copy(
                                        roleType = event.roleType,
                                        roleIndex = event.roleIndex
                                    )
                                } else player
                            }
                            val updatedCurrentPlayer = if (state.currentPlayer?.id == event.playerId) {
                                state.currentPlayer.copy(
                                    roleType = event.roleType,
                                    roleIndex = event.roleIndex
                                )
                            } else state.currentPlayer

                            state.copy(
                                players = updatedPlayers,
                                currentPlayer = updatedCurrentPlayer
                            )
                        }
                    }

                    is WebSocketEvent.Connected -> {
                        Log.d(TAG, "WebSocket connected")
                        refreshPlayers()
                    }

                    is WebSocketEvent.Error -> {
                        Log.e(TAG, "WebSocket error: ${event.message}")
                    }

                    else -> {}
                }
            }
        }
    }

    fun createRoom(nickname: String, onSuccess: (roomCode: String, playerId: String) -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val response = apiService.createRoom(CreateRoomRequest(nickname))
                Log.d(TAG, "Room created: ${response.code}, playerId: ${response.playerId}")

                // Create a Player object from the response
                val hostPlayer = Player(
                    id = response.playerId,
                    nickname = nickname,
                    isHost = true
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        roomCode = response.code,
                        currentPlayer = hostPlayer,
                        players = listOf(hostPlayer),
                        isHost = true
                    )
                }

                // Connect WebSocket
                webSocketService.connect(response.code, response.playerId)

                onSuccess(response.code, response.playerId)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to create room", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "建立房間失敗: ${e.message}"
                    )
                }
            }
        }
    }

    fun joinRoom(code: String, nickname: String, onSuccess: (playerId: String) -> Unit) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val response = apiService.joinRoom(code, JoinRoomRequest(nickname))
                Log.d(TAG, "Joined room: $code, playerId: ${response.playerId}")

                // Create a Player object from the response
                val joinedPlayer = Player(
                    id = response.playerId,
                    nickname = nickname,
                    isHost = false
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        roomCode = code,
                        currentPlayer = joinedPlayer,
                        isHost = false
                    )
                }

                // Connect WebSocket
                webSocketService.connect(code, response.playerId)

                onSuccess(response.playerId)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to join room", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "加入房間失敗: ${e.message}"
                    )
                }
            }
        }
    }

    fun refreshPlayers(code: String? = null) {
        val roomCode = code ?: _uiState.value.roomCode ?: return

        // Update roomCode if provided
        if (code != null && _uiState.value.roomCode == null) {
            _uiState.update { it.copy(roomCode = code) }
        }

        viewModelScope.launch {
            try {
                val players = apiService.getPlayers(roomCode)
                Log.d(TAG, "Fetched ${players.size} players")
                _uiState.update { it.copy(players = players) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch players", e)
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun disconnect() {
        webSocketService.disconnect()
    }

    override fun onCleared() {
        super.onCleared()
        disconnect()
    }
}
