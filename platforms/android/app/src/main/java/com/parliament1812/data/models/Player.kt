package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Player(
    val id: String,
    val nickname: String,
    @SerialName("is_host") val isHost: Boolean = false,
    @SerialName("role_type") val roleType: String? = null,
    @SerialName("role_index") val roleIndex: Int? = null,
    @SerialName("is_ready") val isReady: Boolean = false,
    @SerialName("secret_mission_id") val secretMissionId: String? = null
) {
    val hasRole: Boolean get() = roleType != null

    val displayRoleName: String
        get() = when (roleType) {
            "worker" -> "工人"
            "factory_owner" -> "工廠主"
            "luddite" -> "盧德派"
            "reformer" -> "改革者"
            "mp" -> "議員"
            "george_iii" -> "喬治三世"
            else -> "未知"
        }

    val roleEmoji: String
        get() = when (roleType) {
            "worker" -> "W"
            "factory_owner" -> "F"
            "luddite" -> "L"
            "reformer" -> "R"
            "mp" -> "M"
            "george_iii" -> "G"
            else -> "?"
        }
}
