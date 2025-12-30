package com.parliament1812.data.remote

import com.parliament1812.data.models.Player
import com.parliament1812.data.models.Role
import com.parliament1812.data.models.Room
import com.parliament1812.data.models.SecretMission
import retrofit2.http.*

interface ApiService {

    // ========== Room Management ==========

    @POST("api/rooms")
    suspend fun createRoom(@Body request: CreateRoomRequest): CreateRoomResponse

    @GET("api/rooms/{code}")
    suspend fun getRoom(@Path("code") code: String): Room

    @GET("api/rooms/{code}")
    suspend fun getRoomDetail(@Path("code") code: String): RoomDetailResponse

    @POST("api/rooms/{code}/join")
    suspend fun joinRoom(
        @Path("code") code: String,
        @Body request: JoinRoomRequest
    ): JoinRoomResponse

    @GET("api/rooms/{code}/players")
    suspend fun getPlayers(@Path("code") code: String): List<Player>

    @DELETE("api/rooms/{code}/leave")
    suspend fun leaveRoom(
        @Path("code") code: String,
        @Query("player_id") playerId: String
    )

    @POST("api/rooms/{code}/phase")
    suspend fun changePhase(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Body request: PhaseChangeRequest
    ): RoomDetailResponse

    @POST("api/rooms/{code}/timer")
    suspend fun setTimer(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Body request: TimerRequest
    ): RoomDetailResponse

    @POST("api/rooms/{code}/start")
    suspend fun startGame(
        @Path("code") code: String,
        @Query("player_id") playerId: String
    ): RoomDetailResponse

    @DELETE("api/rooms/{code}")
    suspend fun deleteRoom(
        @Path("code") code: String,
        @Query("player_id") playerId: String
    )

    // ========== NFC / Role Assignment ==========

    @POST("api/rooms/{code}/scan-nfc")
    suspend fun scanNFC(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Body request: NFCScanBodyRequest
    ): NFCScanResponse

    @POST("api/rooms/{code}/assign-role-manual")
    suspend fun assignRoleManually(
        @Path("code") code: String,
        @Body request: ManualRoleRequest
    ): ManualRoleResponse

    @GET("api/roles")
    suspend fun getRoles(): List<Role>

    @GET("api/roles/{roleType}")
    suspend fun getRole(@Path("roleType") roleType: String): Role

    @GET("api/players/{playerId}/secret-mission")
    suspend fun getSecretMission(@Path("playerId") playerId: String): SecretMission

    @PUT("api/players/{playerId}/ready")
    suspend fun setReady(
        @Path("playerId") playerId: String,
        @Body request: SetReadyRequest
    ): Player

    // ========== Private Messages ==========

    @POST("api/messages")
    suspend fun sendMessage(
        @Query("sender_id") senderId: String,
        @Query("room_code") roomCode: String,
        @Body request: SendMessageRequest
    ): MessageResponse

    @GET("api/messages")
    suspend fun getMessages(
        @Query("player_id") playerId: String,
        @Query("room_code") roomCode: String,
        @Query("other_player_id") otherPlayerId: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): MessageListResponse

    @GET("api/messages/conversations")
    suspend fun getConversations(
        @Query("player_id") playerId: String,
        @Query("room_code") roomCode: String
    ): ConversationsResponse

    @PUT("api/messages/read")
    suspend fun markAsRead(
        @Query("player_id") playerId: String,
        @Query("sender_id") senderId: String? = null,
        @Body request: MarkReadRequest
    ): Map<String, Any>

    @GET("api/messages/unread-count")
    suspend fun getUnreadCount(
        @Query("player_id") playerId: String,
        @Query("room_code") roomCode: String
    ): UnreadCountResponse

    // ========== Voting ==========

    @POST("api/rooms/{code}/votes")
    suspend fun castVote(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Query("vote_round") voteRound: Int,
        @Body request: VoteRequest
    ): VoteResponse

    @GET("api/rooms/{code}/votes/progress")
    suspend fun getVoteProgress(
        @Path("code") code: String,
        @Query("vote_round") voteRound: Int
    ): VoteProgressResponse

    @GET("api/rooms/{code}/votes/result")
    suspend fun getVoteResult(
        @Path("code") code: String,
        @Query("vote_round") voteRound: Int
    ): Map<String, Any>

    @GET("api/rooms/{code}/votes/my-vote")
    suspend fun getMyVote(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Query("vote_round") voteRound: Int
    ): MyVoteResponse

    @GET("api/rooms/{code}/votes/options")
    suspend fun getVoteOptions(
        @Path("code") code: String,
        @Query("include_hidden") includeHidden: Boolean = false
    ): List<VoteOption>

    // ========== Events ==========

    @GET("api/rooms/{code}/events")
    suspend fun getAvailableEvents(
        @Path("code") code: String,
        @Query("player_id") playerId: String
    ): List<EventResponse>

    @POST("api/rooms/{code}/events/trigger")
    suspend fun triggerEvent(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Body request: TriggerEventRequest
    ): GameEventResponse

    @POST("api/rooms/{code}/events/random")
    suspend fun triggerRandomEvent(
        @Path("code") code: String,
        @Query("player_id") playerId: String,
        @Query("min_severity") minSeverity: Int = 1,
        @Query("max_severity") maxSeverity: Int = 5
    ): GameEventResponse

    @GET("api/rooms/{code}/events/history")
    suspend fun getEventHistory(
        @Path("code") code: String
    ): List<GameEventResponse>

    @GET("api/rooms/{code}/events/{eventId}")
    suspend fun getEventDetail(
        @Path("code") code: String,
        @Path("eventId") eventId: String
    ): Map<String, Any>
}
