package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.models.*
import com.parliament1812.data.remote.PlayerBrief
import com.parliament1812.ui.components.*
import com.parliament1812.ui.components.CharacterPortraitSmall
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.GameViewModel
import kotlinx.coroutines.delay

// Phase definitions
object GamePhase {
    const val WAITING = 1
    const val PREPARING = 2
    const val CONSPIRACY = 3
    const val DEBATE = 4
    const val EVENT1 = 5
    const val DEBATE2 = 6
    const val EVENT2 = 7
    const val VOTE_ROUND1 = 8
    const val FINAL_DEBATE = 9
    const val VOTE_ROUND2 = 10
    const val REVEAL = 11
    const val FINISHED = 12

    fun getPhaseName(phase: Int): String = when (phase) {
        WAITING -> "等待中"
        PREPARING -> "角色研究"
        CONSPIRACY -> "私下密謀"
        DEBATE -> "開場陳述"
        EVENT1 -> "突發事件"
        DEBATE2 -> "自由辯論"
        EVENT2 -> "突發事件"
        VOTE_ROUND1 -> "第一輪投票"
        FINAL_DEBATE -> "最後攻防"
        VOTE_ROUND2 -> "第二輪投票"
        REVEAL -> "結果揭曉"
        FINISHED -> "遊戲結束"
        else -> "未知"
    }

    fun getPhaseEnglishName(phase: Int): String = when (phase) {
        WAITING -> "WAITING"
        PREPARING -> "PREPARATION"
        CONSPIRACY -> "CONSPIRACY"
        DEBATE -> "OPENING STATEMENTS"
        EVENT1 -> "SUDDEN EVENT"
        DEBATE2 -> "FREE DEBATE"
        EVENT2 -> "SUDDEN EVENT"
        VOTE_ROUND1 -> "FIRST VOTE"
        FINAL_DEBATE -> "FINAL DEBATE"
        VOTE_ROUND2 -> "FINAL VOTE"
        REVEAL -> "REVELATION"
        FINISHED -> "FINISHED"
        else -> "UNKNOWN"
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameScreen(
    roomCode: String,
    playerId: String,
    isHost: Boolean,
    onNavigateToMessages: () -> Unit,
    onNavigateToVote: (Int) -> Unit,
    onNavigateToDebate: () -> Unit = {},
    onNavigateToHostPanel: () -> Unit,
    onNavigateToResult: () -> Unit,
    viewModel: GameViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Load room data on launch
    LaunchedEffect(roomCode) {
        viewModel.loadRoomData(roomCode, playerId)
    }

    // Timer countdown
    var remainingSeconds by remember { mutableStateOf(0L) }
    LaunchedEffect(uiState.timerEndAt) {
        uiState.timerEndAt?.let { endTime ->
            while (true) {
                val now = System.currentTimeMillis()
                val remaining = (endTime - now) / 1000
                remainingSeconds = if (remaining > 0) remaining else 0
                delay(1000)
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Background
        Image(
            painter = painterResource(id = R.drawable.bg_parliament),
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )

        // Dark Overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(DarkOverlay80)
        )

        // Hexagonal Pattern
        HexagonalPattern(
            modifier = Modifier.fillMaxSize(),
            hexSize = 45f,
            color = Gold.copy(alpha = 0.02f)
        )

        // Ambient Particles
        AmbientParticles(
            modifier = Modifier.fillMaxSize(),
            particleCount = 10
        )

        // Vignette Effect
        VignetteOverlay(
            modifier = Modifier.fillMaxSize(),
            intensity = 0.5f
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Top Header with Phase Info
            GameHeader(
                roomCode = roomCode,
                phase = uiState.phase,
                remainingSeconds = remainingSeconds,
                unreadMessages = uiState.unreadCount,
                isHost = isHost,
                onMessagesClick = onNavigateToMessages,
                onHostPanelClick = onNavigateToHostPanel
            )

            // Phase Progress Bar (shown during active game phases)
            if (uiState.phase in 2..11) {
                PhaseProgressBar(
                    currentPhase = uiState.phase,
                    timerEndAt = uiState.timerEndAt,
                    timerDuration = uiState.timerDuration,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }

            // Main Content
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // My Role Card (compact)
                item {
                    MyRoleCompactCard(
                        roleType = uiState.myRoleType,
                        roleName = uiState.myRoleName,
                        roleOccupation = uiState.myRoleOccupation
                    )
                }

                // Current Event (if any)
                uiState.currentEvent?.let { event ->
                    item {
                        EventCardFull(event = event)
                    }
                }

                // Phase-specific content
                item {
                    PhaseContentCard(
                        phase = uiState.phase,
                        onVoteClick = { onNavigateToVote(if (uiState.phase == GamePhase.VOTE_ROUND1) 1 else 2) }
                    )
                }

                // Players in Room
                item {
                    Text(
                        text = "議會成員",
                        color = Gold,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }

                items(uiState.players) { player ->
                    PlayerListItem(
                        player = player,
                        isMe = player.id == playerId,
                        onMessageClick = { onNavigateToMessages() }
                    )
                }

                item { Spacer(modifier = Modifier.height(80.dp)) }
            }
        }

        // Bottom Action Bar
        BottomActionBar(
            phase = uiState.phase,
            isHost = isHost,
            onVoteClick = { onNavigateToVote(if (uiState.phase == GamePhase.VOTE_ROUND1) 1 else 2) },
            onResultClick = onNavigateToResult,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
        )

        // Dice Roll Overlay for International Events (Phase 5 and 7)
        DiceRollView(
            value = uiState.diceRoll.value,
            threshold = uiState.diceRoll.threshold,
            triggered = uiState.diceRoll.triggered,
            isVisible = uiState.diceRoll.isVisible,
            onDismiss = { viewModel.dismissDiceRoll() },
            modifier = Modifier.fillMaxSize()
        )

        // Vote Progress Overlay
        if (uiState.voteProgress.isActive) {
            VoteProgressOverlay(
                voteProgress = uiState.voteProgress,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

@Composable
private fun GameHeader(
    roomCode: String,
    phase: Int,
    remainingSeconds: Long,
    unreadMessages: Int,
    isHost: Boolean,
    onMessagesClick: () -> Unit,
    onHostPanelClick: () -> Unit
) {
    Surface(
        color = DarkOverlay95,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Room Code
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "房間 $roomCode",
                        color = TextMuted,
                        fontSize = 12.sp
                    )
                    Text(
                        text = GamePhase.getPhaseName(phase),
                        color = Gold,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = GamePhase.getPhaseEnglishName(phase),
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                // Timer
                if (remainingSeconds > 0) {
                    TimerDisplay(remainingSeconds)
                    Spacer(modifier = Modifier.width(12.dp))
                }

                // Messages Button
                BadgedBox(
                    badge = {
                        if (unreadMessages > 0) {
                            Badge(
                                containerColor = Error,
                                contentColor = Color.White
                            ) {
                                Text(if (unreadMessages > 99) "99+" else unreadMessages.toString())
                            }
                        }
                    }
                ) {
                    IconButton(onClick = onMessagesClick) {
                        Icon(
                            imageVector = Icons.Default.Email,
                            contentDescription = "私訊",
                            tint = Gold
                        )
                    }
                }

                // Host Panel Button
                if (isHost) {
                    IconButton(onClick = onHostPanelClick) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "主持人控制台",
                            tint = Gold
                        )
                    }
                }
            }

            GoldDivider(modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun TimerDisplay(remainingSeconds: Long) {
    val minutes = remainingSeconds / 60
    val seconds = remainingSeconds % 60
    val isUrgent = remainingSeconds < 60

    // Pulsing animation for urgent timer
    val infiniteTransition = rememberInfiniteTransition(label = "timerPulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isUrgent) 0.6f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )

    val timerShape = CutCornerShape(topEnd = 6.dp, bottomStart = 6.dp)

    Box(
        modifier = Modifier
            .clip(timerShape)
            .background(
                if (isUrgent) Error.copy(alpha = 0.2f * pulseAlpha) else DarkSurfaceVariant
            )
            .border(
                width = 1.dp,
                brush = if (isUrgent) {
                    Brush.linearGradient(listOf(Error, Error.copy(alpha = 0.5f)))
                } else {
                    Brush.linearGradient(listOf(Gold.copy(alpha = 0.5f), Gold.copy(alpha = 0.3f)))
                },
                shape = timerShape
            )
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(
            text = String.format("%02d:%02d", minutes, seconds),
            color = if (isUrgent) Error.copy(alpha = pulseAlpha) else Gold,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace
        )
    }
}

@Composable
private fun MyRoleCompactCard(
    roleType: String?,
    roleName: String?,
    roleOccupation: String?
) {
    val roleColor = when (roleType) {
        "worker" -> WorkerColor
        "factory" -> FactoryColor
        "luddite" -> LudditeColor
        "reformer" -> ReformerColor
        "mp" -> MPColor
        "george" -> GeorgeIIIColor
        else -> Gold
    }

    val cardShape = CutCornerShape(topEnd = 16.dp, bottomStart = 16.dp)

    // Subtle shimmer animation
    val infiniteTransition = rememberInfiniteTransition(label = "roleCardShimmer")
    val shimmerAlpha by infiniteTransition.animateFloat(
        initialValue = 0.1f,
        targetValue = 0.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "shimmerAlpha"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    listOf(roleColor.copy(alpha = 0.6f), Gold.copy(alpha = 0.3f), roleColor.copy(alpha = 0.6f))
                ),
                shape = cardShape
            ),
        colors = CardDefaults.cardColors(
            containerColor = roleColor.copy(alpha = shimmerAlpha)
        ),
        shape = cardShape
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Role Portrait - 文明6風格肖像
            if (roleType != null) {
                CharacterPortraitSmall(
                    roleType = roleType,
                    size = 52.dp,
                    showBorder = true
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.radialGradient(
                                listOf(GoldMuted, GoldMuted.copy(alpha = 0.5f))
                            )
                        )
                        .border(2.dp, Gold, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null,
                        tint = TextPrimary,
                        modifier = Modifier.size(30.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "◇ 你的角色",
                    color = Gold,
                    fontSize = 10.sp,
                    letterSpacing = 2.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = roleName ?: "未分配",
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
                roleOccupation?.let {
                    Text(
                        text = it,
                        color = roleColor,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Icon(
                imageVector = Icons.Default.Visibility,
                contentDescription = "查看詳情",
                tint = Gold,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
private fun PhaseContentCard(
    phase: Int,
    onVoteClick: () -> Unit
) {
    val (title, description, showVoteButton) = when (phase) {
        GamePhase.PREPARING -> Triple(
            "研究你的角色",
            "仔細閱讀你的角色背景和秘密任務。思考如何在不暴露真實意圖的情況下完成任務。",
            false
        )
        GamePhase.CONSPIRACY -> Triple(
            "私下密謀時間",
            "現在是與其他玩家私下交流的時間。透過私訊功能與你認為可以合作的人建立聯盟。",
            false
        )
        GamePhase.DEBATE, GamePhase.DEBATE2 -> Triple(
            "辯論進行中",
            "請依據你的角色立場發表意見。記住：你的公開立場和秘密任務可能不同！",
            false
        )
        GamePhase.FINAL_DEBATE -> Triple(
            "最後攻防",
            "這是最後的辯論機會。在第二輪投票前，試著說服其他人支持你的立場。",
            false
        )
        GamePhase.VOTE_ROUND1 -> Triple(
            "第一輪匿名投票",
            "請投下你的一票。此輪投票為匿名，只會顯示各選項的百分比。",
            true
        )
        GamePhase.VOTE_ROUND2 -> Triple(
            "第二輪記名投票",
            "這是最終投票。此輪為記名投票，每個人的選擇都會公開。",
            true
        )
        GamePhase.REVEAL -> Triple(
            "結果揭曉",
            "遊戲即將結束。現在將公開所有人的秘密任務和最終結果。",
            false
        )
        else -> Triple(
            "請稍候",
            "等待主持人開始下一階段。",
            false
        )
    }

    val cardShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, CardBorderGold, cardShape),
        colors = CardDefaults.cardColors(containerColor = DarkOverlay95),
        shape = cardShape
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "◇", color = Gold, fontSize = 12.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = title,
                    color = Gold,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = description,
                color = TextSecondary,
                fontSize = 14.sp,
                lineHeight = 20.sp
            )

            if (showVoteButton) {
                Spacer(modifier = Modifier.height(16.dp))

                GoldDivider(modifier = Modifier.fillMaxWidth())

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = onVoteClick,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Gold,
                        contentColor = DarkBackground
                    ),
                    shape = CutCornerShape(bottomEnd = 12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.HowToVote,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "前往投票",
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        letterSpacing = 2.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun PlayerListItem(
    player: PlayerBrief,
    isMe: Boolean,
    onMessageClick: () -> Unit
) {
    val roleColor = when (player.roleType) {
        "worker" -> WorkerColor
        "factory" -> FactoryColor
        "luddite" -> LudditeColor
        "reformer" -> ReformerColor
        "mp" -> MPColor
        "george" -> GeorgeIIIColor
        else -> GoldMuted
    }

    val cardShape = CutCornerShape(topEnd = 8.dp, bottomStart = 8.dp)

    // Subtle animation for current player
    val infiniteTransition = rememberInfiniteTransition(label = "playerPulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isMe) 1.01f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .scale(pulseScale)
            .then(
                if (isMe) {
                    Modifier.border(
                        width = 1.dp,
                        brush = Brush.linearGradient(listOf(Gold, Gold.copy(alpha = 0.5f), Gold)),
                        shape = cardShape
                    )
                } else {
                    Modifier.border(1.dp, CardBorderGold, cardShape)
                }
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isMe) Gold.copy(alpha = 0.12f) else DarkOverlay95
        ),
        shape = cardShape
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            listOf(roleColor, roleColor.copy(alpha = 0.5f))
                        )
                    )
                    .border(2.dp, if (isMe) Gold else roleColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = player.nickname.take(1).uppercase(),
                    color = TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Name and Role
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = player.nickname,
                        color = if (isMe) Gold else TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = if (isMe) FontWeight.Bold else FontWeight.Medium
                    )
                    if (isMe) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "(你)",
                            color = GoldAccent,
                            fontSize = 11.sp
                        )
                    }
                    if (player.isHost) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "◆", fontSize = 12.sp, color = Gold)
                    }
                }
                player.roleType?.let { roleType ->
                    Text(
                        text = getRoleDisplayName(roleType),
                        color = roleColor,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            // Message Button (not for self)
            if (!isMe) {
                IconButton(
                    onClick = onMessageClick,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = "發送私訊",
                        tint = Gold,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun BottomActionBar(
    phase: Int,
    isHost: Boolean,
    onVoteClick: () -> Unit,
    onResultClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val showVote = phase == GamePhase.VOTE_ROUND1 || phase == GamePhase.VOTE_ROUND2
    val showResult = phase == GamePhase.REVEAL || phase == GamePhase.FINISHED

    if (showVote || showResult) {
        Surface(
            color = DarkOverlay95,
            modifier = modifier.fillMaxWidth()
        ) {
            Column {
                GoldDivider(modifier = Modifier.fillMaxWidth())
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.Center
                ) {
                    if (showVote) {
                        Button(
                            onClick = onVoteClick,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Gold,
                                contentColor = DarkBackground
                            ),
                            shape = CutCornerShape(bottomEnd = 16.dp),
                            modifier = Modifier
                                .fillMaxWidth(0.85f)
                                .height(52.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.HowToVote,
                                contentDescription = null,
                                modifier = Modifier.size(22.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = if (phase == GamePhase.VOTE_ROUND1) "☆ 第一輪投票" else "★ 最終投票",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                letterSpacing = 2.sp
                            )
                        }
                    } else if (showResult) {
                        Button(
                            onClick = onResultClick,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Gold,
                                contentColor = DarkBackground
                            ),
                            shape = CutCornerShape(bottomEnd = 16.dp),
                            modifier = Modifier
                                .fillMaxWidth(0.85f)
                                .height(52.dp)
                        ) {
                            Text(text = "🏆", fontSize = 20.sp)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "查看結果",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                letterSpacing = 2.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

private fun getRoleDisplayName(roleType: String): String = when (roleType) {
    "worker" -> "紡織工人"
    "factory" -> "工廠主"
    "luddite" -> "盧德派"
    "reformer" -> "改革者"
    "mp" -> "議員"
    "george" -> "喬治三世"
    else -> "未知"
}

/**
 * Vote progress overlay showing real-time voting status
 */
@Composable
private fun VoteProgressOverlay(
    voteProgress: com.parliament1812.viewmodels.VoteProgressState,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.7f)),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth(0.85f)
                .border(1.dp, Gold.copy(alpha = 0.5f), RoundedCornerShape(16.dp)),
            colors = CardDefaults.cardColors(containerColor = DarkBackground),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Title
                Text(
                    text = if (voteProgress.isAnonymous) "匿名投票中" else "記名投票中",
                    color = Gold,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = if (voteProgress.round == 1) "ANONYMOUS VOTE" else "ROLL CALL VOTE",
                    color = TextMuted,
                    fontSize = 12.sp,
                    letterSpacing = 2.sp
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Progress ring animation
                Box(
                    modifier = Modifier.size(120.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        progress = { voteProgress.progress.toFloat() },
                        modifier = Modifier.size(120.dp),
                        color = Gold,
                        strokeWidth = 8.dp,
                        trackColor = CardBorder
                    )

                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "${voteProgress.votedCount}/${voteProgress.totalPlayers}",
                            color = TextPrimary,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "已投票",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Percentage
                Text(
                    text = "${(voteProgress.progress * 100).toInt()}%",
                    color = Gold,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold
                )

                // Winning result (when vote ended)
                voteProgress.winningChoice?.let { winner ->
                    Spacer(modifier = Modifier.height(16.dp))
                    GoldDivider(modifier = Modifier.fillMaxWidth())
                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "投票結果",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "選項 $winner 獲勝",
                        color = Success,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
