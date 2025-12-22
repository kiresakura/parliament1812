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

data class VoteUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val options: List<VoteOption> = emptyList(),
    val selectedChoice: String? = null,
    val hasVoted: Boolean = false,
    val myChoice: String? = null,
    val votedCount: Int = 0,
    val totalPlayers: Int = 0,
    val progress: Float = 0f,
    val showResults: Boolean = false,
    val percentages: Map<String, Float> = emptyMap(),
    val playerVotes: List<Pair<String, String>> = emptyList(),
    val voteSubmitted: Boolean = false
)

@HiltViewModel
class VoteViewModel @Inject constructor(
    private val apiService: ApiService
) : ViewModel() {

    private val _uiState = MutableStateFlow(VoteUiState())
    val uiState: StateFlow<VoteUiState> = _uiState.asStateFlow()

    fun loadVoteData(roomCode: String, playerId: String, voteRound: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                // Load vote options
                val options = apiService.getVoteOptions(roomCode)

                // Load vote progress
                val progress = apiService.getVoteProgress(roomCode, voteRound)

                // Check if already voted
                val myVote = apiService.getMyVote(roomCode, playerId, voteRound)

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        options = options,
                        votedCount = progress.votedCount,
                        totalPlayers = progress.totalPlayers,
                        progress = progress.progress,
                        hasVoted = myVote.hasVoted,
                        myChoice = myVote.vote?.choice,
                        showResults = progress.isComplete
                    )
                }

                // Load results if voting is complete
                if (progress.isComplete) {
                    loadResults(roomCode, voteRound)
                }

            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "載入失敗：${e.message}")
                }
            }
        }
    }

    private suspend fun loadResults(roomCode: String, voteRound: Int) {
        try {
            val result = apiService.getVoteResult(roomCode, voteRound)

            // Parse percentages from result
            @Suppress("UNCHECKED_CAST")
            val percentages = (result["percentages"] as? Map<String, Number>)
                ?.mapValues { it.value.toFloat() }
                ?: emptyMap()

            // For round 2, parse player votes
            @Suppress("UNCHECKED_CAST")
            val votes = (result["votes"] as? List<Map<String, Any>>)?.map { vote ->
                val nickname = vote["nickname"] as? String ?: ""
                val choice = vote["choice"] as? String ?: ""
                nickname to choice
            } ?: emptyList()

            _uiState.update {
                it.copy(
                    showResults = true,
                    percentages = percentages,
                    playerVotes = votes
                )
            }
        } catch (e: Exception) {
            // Non-critical, just log
        }
    }

    fun selectOption(optionId: String) {
        _uiState.update { it.copy(selectedChoice = optionId) }
    }

    fun submitVote(roomCode: String, playerId: String, voteRound: Int) {
        val choice = _uiState.value.selectedChoice ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                apiService.castVote(
                    code = roomCode,
                    playerId = playerId,
                    voteRound = voteRound,
                    request = VoteRequest(choice = choice)
                )

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        hasVoted = true,
                        myChoice = choice,
                        voteSubmitted = true
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(isLoading = false, error = "投票失敗：${e.message}")
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
