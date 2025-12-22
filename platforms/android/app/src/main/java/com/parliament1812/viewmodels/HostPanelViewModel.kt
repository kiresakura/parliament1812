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

data class HostPanelUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null,
    val currentPhase: Int = 1,
    val timerEndAt: Long? = null,
    val playerCount: Int = 0,
    val availableEvents: List<EventResponse> = emptyList(),
    val triggeredEvent: EventResponse? = null,
    val isChangingPhase: Boolean = false,
    val isSettingTimer: Boolean = false,
    val isTriggeringEvent: Boolean = false
)

@HiltViewModel
class HostPanelViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(HostPanelUiState())
    val uiState: StateFlow<HostPanelUiState> = _uiState.asStateFlow()

    private var roomCode: String = ""
    private var hostPlayerId: String = ""

    fun initialize(roomCode: String, playerId: String) {
        this.roomCode = roomCode
        this.hostPlayerId = playerId
        loadRoomData()
        loadAvailableEvents()
    }

    private fun loadRoomData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                val room = apiService.getRoomDetail(roomCode)
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
                        currentPhase = room.phase,
                        timerEndAt = timerEndAt,
                        playerCount = room.playerCount
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入失敗：${e.message}")
                }
            }
        }
    }

    private fun loadAvailableEvents() {
        viewModelScope.launch {
            try {
                val events = apiService.getAvailableEvents(roomCode, hostPlayerId)
                _uiState.update { it.copy(availableEvents = events) }
            } catch (e: Exception) {
                // Non-critical
            }
        }
    }

    fun changePhase(newPhase: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isChangingPhase = true, error = null) }
            try {
                apiService.changePhase(
                    code = roomCode,
                    playerId = hostPlayerId,
                    request = PhaseChangeRequest(phase = newPhase)
                )

                _uiState.update {
                    it.copy(
                        isChangingPhase = false,
                        currentPhase = newPhase,
                        successMessage = "已切換到階段 $newPhase"
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isChangingPhase = false, error = "切換階段失敗：${e.message}")
                }
            }
        }
    }

    fun setTimer(durationSeconds: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSettingTimer = true, error = null) }
            try {
                val room = apiService.setTimer(
                    code = roomCode,
                    playerId = hostPlayerId,
                    request = TimerRequest(durationSeconds = durationSeconds)
                )

                val timerEndAt = room.timerEndAt?.let {
                    try {
                        java.time.Instant.parse(it).toEpochMilli()
                    } catch (e: Exception) {
                        null
                    }
                }

                _uiState.update {
                    it.copy(
                        isSettingTimer = false,
                        timerEndAt = timerEndAt,
                        successMessage = "計時器已設定"
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isSettingTimer = false, error = "設定計時器失敗：${e.message}")
                }
            }
        }
    }

    fun triggerEvent(eventId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isTriggeringEvent = true, error = null) }
            try {
                val response = apiService.triggerEvent(
                    code = roomCode,
                    playerId = hostPlayerId,
                    request = TriggerEventRequest(eventId = eventId)
                )

                _uiState.update {
                    it.copy(
                        isTriggeringEvent = false,
                        triggeredEvent = response.event,
                        successMessage = "事件已觸發：${response.event.title}"
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isTriggeringEvent = false, error = "觸發事件失敗：${e.message}")
                }
            }
        }
    }

    fun triggerRandomEvent(minSeverity: Int = 1, maxSeverity: Int = 5) {
        viewModelScope.launch {
            _uiState.update { it.copy(isTriggeringEvent = true, error = null) }
            try {
                val response = apiService.triggerRandomEvent(
                    code = roomCode,
                    playerId = hostPlayerId,
                    minSeverity = minSeverity,
                    maxSeverity = maxSeverity
                )

                _uiState.update {
                    it.copy(
                        isTriggeringEvent = false,
                        triggeredEvent = response.event,
                        successMessage = "隨機事件已觸發：${response.event.title}"
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isTriggeringEvent = false, error = "觸發事件失敗：${e.message}")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun clearSuccessMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }

    fun clearTriggeredEvent() {
        _uiState.update { it.copy(triggeredEvent = null) }
    }

    fun refreshData() {
        loadRoomData()
        loadAvailableEvents()
    }
}
