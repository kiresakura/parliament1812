package com.parliament1812.data.remote

import android.util.Log
import com.parliament1812.data.models.Player
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import javax.inject.Inject
import javax.inject.Singleton

sealed class WebSocketEvent {
    data class PlayerJoined(val player: Player) : WebSocketEvent()
    data class PlayerLeft(val playerId: String) : WebSocketEvent()
    data class PlayerReady(val playerId: String, val isReady: Boolean) : WebSocketEvent()
    data class RoleAssigned(val playerId: String, val roleType: String, val roleIndex: Int) : WebSocketEvent()
    object GameStarted : WebSocketEvent()
    object VoteStarted : WebSocketEvent()
    object VoteEnded : WebSocketEvent()
    data class Error(val message: String) : WebSocketEvent()
    object Connected : WebSocketEvent()
    object Disconnected : WebSocketEvent()
    data class PlayersUpdated(val players: List<Player>) : WebSocketEvent()

    // Generic message event for handling various server messages
    data class GenericMessage(val type: String, val data: Map<String, String>?) : WebSocketEvent()

    // Auto Game Flow Events
    data class PhaseChanged(val phase: Int) : WebSocketEvent()
    data class TimerSync(val endAt: Long, val duration: Int) : WebSocketEvent()
    data class DiceRoll(val value: Int, val threshold: Int, val triggered: Boolean) : WebSocketEvent()
    data class VoteStart(val round: Int, val isAnonymous: Boolean) : WebSocketEvent()
    data class VoteUpdate(val round: Int, val votedCount: Int, val totalPlayers: Int, val progress: Double) : WebSocketEvent()
    data class VoteResult(val round: Int, val percentages: Map<String, Double>, val winningChoice: String?) : WebSocketEvent()
    data class EventTrigger(val eventId: String, val title: String, val description: String, val effectType: String?) : WebSocketEvent()
    data class FinalResults(val data: Map<String, String>) : WebSocketEvent()
}

sealed class ConnectionState {
    object Disconnected : ConnectionState()
    object Connecting : ConnectionState()
    object Connected : ConnectionState()
    data class Error(val message: String) : ConnectionState()
}

@Singleton
class WebSocketService @Inject constructor(
    private val okHttpClient: OkHttpClient
) {
    private var webSocket: WebSocket? = null
    private val scope = CoroutineScope(Dispatchers.IO)
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val _events = MutableSharedFlow<WebSocketEvent>(
        replay = 1,
        extraBufferCapacity = 10
    )
    val events: SharedFlow<WebSocketEvent> = _events

    private val _connectionState = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    val connectionState: StateFlow<ConnectionState> = _connectionState

    companion object {
        private const val TAG = "WebSocketService"
        private const val BASE_URL = "wss://1812-production.up.railway.app/ws"
    }

    fun connect(roomCode: String, playerId: String) {
        if (_connectionState.value is ConnectionState.Connected) {
            Log.d(TAG, "Already connected, disconnecting first")
            disconnect()
        }

        _connectionState.value = ConnectionState.Connecting

        val url = "$BASE_URL/$roomCode?player_id=$playerId"
        Log.d(TAG, "Connecting to: $url")

        val request = Request.Builder()
            .url(url)
            .build()

        webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.d(TAG, "WebSocket connected")
                _connectionState.value = ConnectionState.Connected
                scope.launch { _events.emit(WebSocketEvent.Connected) }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                Log.d(TAG, "Message received: $text")
                scope.launch { handleMessage(text) }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "WebSocket closed: $code - $reason")
                _connectionState.value = ConnectionState.Disconnected
                scope.launch { _events.emit(WebSocketEvent.Disconnected) }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "WebSocket error", t)
                _connectionState.value = ConnectionState.Error(t.message ?: "Unknown error")
                scope.launch {
                    _events.emit(WebSocketEvent.Error(t.message ?: "連線失敗"))
                }
            }
        })
    }

    fun disconnect() {
        Log.d(TAG, "Disconnecting WebSocket")
        webSocket?.close(1000, "User disconnected")
        webSocket = null
        _connectionState.value = ConnectionState.Disconnected
    }

    fun sendMessage(type: String, data: Map<String, String> = emptyMap()) {
        val message = buildString {
            append("""{"type":"$type"""")
            if (data.isNotEmpty()) {
                append(""","data":{""")
                append(data.entries.joinToString(",") { """"${it.key}":"${it.value}"""" })
                append("}")
            }
            append("}")
        }
        Log.d(TAG, "Sending: $message")
        webSocket?.send(message)
    }

    fun sendEventChoice(eventId: String, choiceId: String) {
        sendMessage("event_choice", mapOf(
            "event_id" to eventId,
            "choice_id" to choiceId
        ))
    }

    private suspend fun handleMessage(text: String) {
        try {
            val jsonElement = json.parseToJsonElement(text)
            val type = jsonElement.jsonObject["type"]?.jsonPrimitive?.content

            when (type) {
                "player_join", "player_joined" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val playerId = data?.get("player_id")?.jsonPrimitive?.content
                    val nickname = data?.get("nickname")?.jsonPrimitive?.content
                    val isHost = data?.get("is_host")?.jsonPrimitive?.content?.toBoolean() ?: false
                    val isReady = data?.get("is_ready")?.jsonPrimitive?.content?.toBoolean() ?: false
                    val roleType = data?.get("role_type")?.jsonPrimitive?.content
                    if (playerId != null && nickname != null) {
                        _events.emit(WebSocketEvent.PlayerJoined(
                            Player(
                                id = playerId,
                                nickname = nickname,
                                isHost = isHost,
                                isReady = isReady,
                                roleType = roleType
                            )
                        ))
                    }
                }

                "player_left" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val playerId = data?.get("player_id")?.jsonPrimitive?.content
                    playerId?.let { _events.emit(WebSocketEvent.PlayerLeft(it)) }
                }

                "player_ready" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val playerId = data?.get("player_id")?.jsonPrimitive?.content
                    val isReady = data?.get("is_ready")?.jsonPrimitive?.content?.toBoolean() ?: false
                    playerId?.let { _events.emit(WebSocketEvent.PlayerReady(it, isReady)) }
                }

                "role_assigned" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val playerId = data?.get("player_id")?.jsonPrimitive?.content
                    val roleType = data?.get("role_type")?.jsonPrimitive?.content
                    val roleIndex = data?.get("role_index")?.jsonPrimitive?.content?.toIntOrNull()

                    if (playerId != null && roleType != null && roleIndex != null) {
                        _events.emit(WebSocketEvent.RoleAssigned(playerId, roleType, roleIndex))
                    }
                }

                "game_started" -> _events.emit(WebSocketEvent.GameStarted)
                "vote_started" -> _events.emit(WebSocketEvent.VoteStarted)
                "vote_ended" -> _events.emit(WebSocketEvent.VoteEnded)

                "players_updated" -> {
                    // Handle bulk player list update
                    Log.d(TAG, "Players updated event received")
                }

                // Handle phase_change
                "phase_change" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val phase = data?.get("phase")?.jsonPrimitive?.content?.toIntOrNull()
                    phase?.let { _events.emit(WebSocketEvent.PhaseChanged(it)) }
                }

                // Handle timer_sync
                "timer_sync" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val endAtStr = data?.get("end_at")?.jsonPrimitive?.content
                    val duration = data?.get("duration")?.jsonPrimitive?.content?.toIntOrNull() ?: 0
                    endAtStr?.let {
                        try {
                            val endAt = java.time.Instant.parse(it).toEpochMilli()
                            _events.emit(WebSocketEvent.TimerSync(endAt, duration))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to parse timer_sync end_at: $it", e)
                        }
                    }
                }

                // Handle dice_roll for international events
                "dice_roll" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val value = data?.get("value")?.jsonPrimitive?.content?.toIntOrNull() ?: 0
                    val threshold = data?.get("threshold")?.jsonPrimitive?.content?.toIntOrNull() ?: 4
                    val triggered = data?.get("triggered")?.jsonPrimitive?.content?.toBoolean() ?: false
                    _events.emit(WebSocketEvent.DiceRoll(value, threshold, triggered))
                }

                // Handle vote_start
                "vote_start" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val round = data?.get("round")?.jsonPrimitive?.content?.toIntOrNull() ?: 1
                    val isAnonymous = data?.get("is_anonymous")?.jsonPrimitive?.content?.toBoolean() ?: true
                    _events.emit(WebSocketEvent.VoteStart(round, isAnonymous))
                }

                // Handle vote_update
                "vote_update" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val round = data?.get("round")?.jsonPrimitive?.content?.toIntOrNull() ?: 1
                    val votedCount = data?.get("voted_count")?.jsonPrimitive?.content?.toIntOrNull() ?: 0
                    val totalPlayers = data?.get("total_players")?.jsonPrimitive?.content?.toIntOrNull() ?: 0
                    val progress = data?.get("progress")?.jsonPrimitive?.content?.toDoubleOrNull() ?: 0.0
                    _events.emit(WebSocketEvent.VoteUpdate(round, votedCount, totalPlayers, progress))
                }

                // Handle vote_result
                "vote_result" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val round = data?.get("round")?.jsonPrimitive?.content?.toIntOrNull() ?: 1
                    val winningChoice = data?.get("winning_choice")?.jsonPrimitive?.content
                    // Parse percentages (simplified - would need proper JSON parsing for nested objects)
                    _events.emit(WebSocketEvent.VoteResult(round, emptyMap(), winningChoice))
                }

                // Handle event_trigger
                "event_trigger" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val eventId = data?.get("event_id")?.jsonPrimitive?.content ?: ""
                    val title = data?.get("event_title")?.jsonPrimitive?.content ?: ""
                    val description = data?.get("event_description")?.jsonPrimitive?.content ?: ""
                    val effectType = data?.get("effect_type")?.jsonPrimitive?.content
                    _events.emit(WebSocketEvent.EventTrigger(eventId, title, description, effectType))
                }

                // Handle final_results
                "final_results" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val dataMap = data?.entries?.associate { entry ->
                        entry.key to (entry.value.jsonPrimitive.content)
                    } ?: emptyMap()
                    _events.emit(WebSocketEvent.FinalResults(dataMap))
                }

                // Handle private_message as generic
                "private_message" -> {
                    val data = jsonElement.jsonObject["data"]?.jsonObject
                    val dataMap = data?.entries?.associate { entry ->
                        entry.key to (entry.value.jsonPrimitive.content)
                    }
                    type?.let {
                        _events.emit(WebSocketEvent.GenericMessage(it, dataMap))
                    }
                }

                else -> {
                    Log.d(TAG, "Unknown message type: $type")
                    // Emit as generic message anyway
                    type?.let {
                        val data = jsonElement.jsonObject["data"]?.jsonObject
                        val dataMap = data?.entries?.associate { entry ->
                            entry.key to (entry.value.jsonPrimitive.content)
                        }
                        _events.emit(WebSocketEvent.GenericMessage(it, dataMap))
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing message: $text", e)
            _events.emit(WebSocketEvent.Error("解析錯誤: ${e.message}"))
        }
    }
}
