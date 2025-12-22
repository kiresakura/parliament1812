package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Role(
    val id: String,
    @SerialName("name_zh") val nameZh: String,
    @SerialName("name_en") val nameEn: String,
    val faction: String,
    val description: String? = null,
    @SerialName("image_url") val imageUrl: String? = null
) {
    val emoji: String
        get() = when (id) {
            "worker" -> "🔨"
            "factory_owner" -> "🏭"
            "luddite" -> "⚔️"
            "reformer" -> "📜"
            "mp" -> "🎩"
            "george_iii" -> "👑"
            else -> "❓"
        }
}

@Serializable
data class SecretMission(
    val id: String,
    @SerialName("role_type") val roleType: String,
    val title: String,
    val description: String,
    @SerialName("success_condition") val successCondition: String? = null,
    val points: Int = 50
)
