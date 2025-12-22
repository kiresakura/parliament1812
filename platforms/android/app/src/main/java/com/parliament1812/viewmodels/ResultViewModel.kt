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

data class PlayerResult(
    val id: String,
    val nickname: String,
    val roleType: String?,
    val roleName: String?,
    val vote1: String?,
    val vote2: String?,
    val secretMissionCompleted: Boolean?
)

data class ResultUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val winner: String? = null,
    val winnerLabel: String = "",
    val round1Percentages: Map<String, Float> = emptyMap(),
    val round2Results: Map<String, Int> = emptyMap(),
    val playerResults: List<PlayerResult> = emptyList(),
    val eventHistory: List<GameEventResponse> = emptyList(),
    val showSecretMissions: Boolean = false
)

@HiltViewModel
class ResultViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ResultUiState())
    val uiState: StateFlow<ResultUiState> = _uiState.asStateFlow()

    fun loadResults(roomCode: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                // Load room details
                val room = apiService.getRoomDetail(roomCode)

                // Load vote results for both rounds
                val round1Result = try {
                    apiService.getVoteResult(roomCode, 1)
                } catch (e: Exception) { emptyMap() }

                val round2Result = try {
                    apiService.getVoteResult(roomCode, 2)
                } catch (e: Exception) { emptyMap() }

                // Parse round 1 percentages
                @Suppress("UNCHECKED_CAST")
                val round1Percentages = (round1Result["percentages"] as? Map<String, Number>)
                    ?.mapValues { it.value.toFloat() }
                    ?: emptyMap()

                // Parse round 2 results
                @Suppress("UNCHECKED_CAST")
                val round2Results = (round2Result["results"] as? Map<String, Number>)
                    ?.mapValues { it.value.toInt() }
                    ?: emptyMap()

                val winner = round2Result["winner"] as? String

                // Parse player votes from round 2
                @Suppress("UNCHECKED_CAST")
                val playerVotes = (round2Result["votes"] as? List<Map<String, Any>>)
                    ?.associate {
                        (it["player_id"] as? String ?: "") to (it["choice"] as? String ?: "")
                    } ?: emptyMap()

                // Build player results
                val playerResults = room.players.map { player ->
                    PlayerResult(
                        id = player.id,
                        nickname = player.nickname,
                        roleType = player.roleType,
                        roleName = null, // Would need additional API call
                        vote1 = null, // Anonymous in round 1
                        vote2 = playerVotes[player.id],
                        secretMissionCompleted = null
                    )
                }

                // Load event history
                val events = try {
                    apiService.getEventHistory(roomCode)
                } catch (e: Exception) { emptyList() }

                // Determine winner label
                val winnerLabel = when (winner) {
                    "A" -> "禁止機器"
                    "B" -> "保護財產"
                    "C" -> "折衷改革"
                    "D" -> "皇家調查"
                    else -> winner ?: "未決定"
                }

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        winner = winner,
                        winnerLabel = winnerLabel,
                        round1Percentages = round1Percentages,
                        round2Results = round2Results,
                        playerResults = playerResults,
                        eventHistory = events
                    )
                }

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入結果失敗：${e.message}")
                }
            }
        }
    }

    fun toggleSecretMissions() {
        _uiState.update { it.copy(showSecretMissions = !it.showSecretMissions) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
