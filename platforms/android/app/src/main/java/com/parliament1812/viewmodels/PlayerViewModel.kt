package com.parliament1812.viewmodels

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.parliament1812.data.models.NFCCardData
import com.parliament1812.data.models.Player
import com.parliament1812.data.models.Role
import com.parliament1812.data.models.SecretMission
import com.parliament1812.data.remote.ApiService
import com.parliament1812.data.remote.ManualRoleRequest
import com.parliament1812.data.remote.NFCScanRequest
import com.parliament1812.nfc.NFCManager
import com.parliament1812.nfc.NFCState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PlayerUiState(
    val isLoading: Boolean = false,
    val currentPlayer: Player? = null,
    val role: Role? = null,
    val secretMission: SecretMission? = null,
    val error: String? = null,
    val roleAssigned: Boolean = false
)

@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val apiService: ApiService,
    private val nfcManager: NFCManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(PlayerUiState())
    val uiState: StateFlow<PlayerUiState> = _uiState.asStateFlow()

    val nfcState: StateFlow<NFCState> = nfcManager.state

    companion object {
        private const val TAG = "PlayerViewModel"
        // Valid role code pattern: W01, F02, L03, R04, M01, G01
        private val ROLE_CODE_PATTERN = Regex("^[WFLRMG][0-9]{2}$", RegexOption.IGNORE_CASE)
    }

    fun setCurrentPlayer(player: Player) {
        _uiState.update { it.copy(currentPlayer = player) }
    }

    fun submitNFCScan(
        roomCode: String,
        playerId: String,
        cardData: NFCCardData,
        onSuccess: (roleType: String, roleIndex: Int) -> Unit
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                Log.d(TAG, "Submitting NFC scan: cardId=${cardData.cardId}")

                val response = apiService.scanNFC(
                    NFCScanRequest(
                        roomCode = roomCode,
                        playerId = playerId,
                        cardId = cardData.cardId,
                        signature = cardData.signature
                    )
                )

                if (response.success && response.roleType != null && response.roleIndex != null) {
                    Log.d(TAG, "Role assigned: ${response.roleType}/${response.roleIndex}")

                    // Update current player
                    _uiState.update { state ->
                        state.copy(
                            isLoading = false,
                            currentPlayer = state.currentPlayer?.copy(
                                roleType = response.roleType,
                                roleIndex = response.roleIndex,
                                secretMissionId = response.secretMissionId
                            ),
                            role = response.role,
                            roleAssigned = true
                        )
                    }

                    // Load secret mission
                    loadSecretMission(playerId)

                    onSuccess(response.roleType, response.roleIndex)
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = response.message ?: "角色分配失敗"
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "NFC scan failed", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "掃描失敗: ${e.message}"
                    )
                }
            }
        }
    }

    fun submitManualCode(
        roomCode: String,
        playerId: String,
        roleCode: String,
        onSuccess: (roleType: String, roleIndex: Int) -> Unit
    ) {
        val code = roleCode.uppercase().trim()

        // Validate format
        if (!ROLE_CODE_PATTERN.matches(code)) {
            _uiState.update {
                it.copy(error = "角色代碼格式錯誤，請輸入如 W01、F02、G01 等格式")
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                Log.d(TAG, "Submitting manual code: $code")

                val response = apiService.assignRoleManually(
                    roomCode,
                    ManualRoleRequest(
                        playerId = playerId,
                        roleCode = code
                    )
                )

                Log.d(TAG, "Role assigned: ${response.roleType}/${response.roleIndex}")

                // Create role from response - map API fields to Role model
                val role = Role(
                    id = response.roleType,
                    nameZh = response.roleName,
                    nameEn = response.roleOccupation,
                    faction = response.roleType,
                    description = "${response.roleDescription}\n\n背景：${response.roleBackground}\n\n公開立場：${response.rolePublicStance}"
                )

                _uiState.update { state ->
                    state.copy(
                        isLoading = false,
                        currentPlayer = state.currentPlayer?.copy(
                            roleType = response.roleType,
                            roleIndex = response.roleIndex,
                            secretMissionId = response.secretMissionId
                        ),
                        role = role,
                        roleAssigned = true
                    )
                }

                // Load secret mission
                loadSecretMission(playerId)

                onSuccess(response.roleType, response.roleIndex)
            } catch (e: Exception) {
                Log.e(TAG, "Manual code submission failed", e)
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = "提交失敗: ${e.message}"
                    )
                }
            }
        }
    }

    private fun loadRole(roleType: String) {
        viewModelScope.launch {
            try {
                val role = apiService.getRole(roleType)
                _uiState.update { it.copy(role = role) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load role", e)
            }
        }
    }

    private fun loadSecretMission(playerId: String) {
        viewModelScope.launch {
            try {
                val mission = apiService.getSecretMission(playerId)
                _uiState.update { it.copy(secretMission = mission) }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load secret mission", e)
            }
        }
    }

    fun resetNFCState() {
        nfcManager.resetState()
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
