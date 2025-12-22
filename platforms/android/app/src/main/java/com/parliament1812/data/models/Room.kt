package com.parliament1812.data.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Room(
    val code: String,
    @SerialName("host_id") val hostId: String,
    val players: List<Player> = emptyList(),
    val status: RoomStatus = RoomStatus.WAITING,
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("max_players") val maxPlayers: Int = 20
) {
    val playerCount: Int get() = players.size
    val readyCount: Int get() = players.count { it.isReady || it.hasRole }
}

@Serializable
enum class RoomStatus {
    @SerialName("waiting") WAITING,
    @SerialName("playing") PLAYING,
    @SerialName("finished") FINISHED
}
