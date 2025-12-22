package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.remote.GameEventResponse
import com.parliament1812.ui.components.*
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.PlayerResult
import com.parliament1812.viewmodels.ResultViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ResultScreen(
    roomCode: String,
    onNavigateBack: () -> Unit,
    onExitGame: () -> Unit,
    viewModel: ResultViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Load results
    LaunchedEffect(roomCode) {
        viewModel.loadResults(roomCode)
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

        // Ambient Particles - more for celebration
        AmbientParticles(
            modifier = Modifier.fillMaxSize(),
            particleCount = 15
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
            // Header
            ResultHeader(onNavigateBack = onNavigateBack)

            // Content
            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Gold)
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    item { Spacer(modifier = Modifier.height(8.dp)) }

                    // Winner Announcement
                    item {
                        WinnerAnnouncementCard(
                            winner = uiState.winner,
                            winnerLabel = uiState.winnerLabel
                        )
                    }

                    // Vote Results Summary
                    item {
                        VoteResultsSummaryCard(
                            round1Percentages = uiState.round1Percentages,
                            round2Results = uiState.round2Results
                        )
                    }

                    // Player Breakdown
                    item {
                        Text(
                            text = "玩家投票記錄",
                            color = Gold,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 2.sp,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }

                    items(uiState.playerResults) { player ->
                        PlayerResultCard(player = player)
                    }

                    // Event History
                    if (uiState.eventHistory.isNotEmpty()) {
                        item {
                            EventHistoryCard(events = uiState.eventHistory)
                        }
                    }

                    // Exit Button
                    item {
                        Spacer(modifier = Modifier.height(20.dp))
                        Button(
                            onClick = onExitGame,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(56.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Gold,
                                contentColor = DarkBackground
                            ),
                            shape = CutCornerShape(bottomEnd = 16.dp)
                        ) {
                            @Suppress("DEPRECATION")
                            Icon(imageVector = Icons.Default.ExitToApp, contentDescription = null)
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "結束遊戲",
                                fontWeight = FontWeight.Bold,
                                fontSize = 17.sp,
                                letterSpacing = 2.sp
                            )
                        }
                    }

                    item { Spacer(modifier = Modifier.height(24.dp)) }
                }
            }
        }

        // Error Snackbar
        uiState.error?.let { error ->
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                action = {
                    TextButton(onClick = { viewModel.clearError() }) {
                        Text("關閉", color = Gold)
                    }
                },
                containerColor = Error.copy(alpha = 0.9f)
            ) {
                Text(error)
            }
        }
    }
}

@Composable
private fun ResultHeader(onNavigateBack: () -> Unit) {
    // Trophy pulsing animation
    val infiniteTransition = rememberInfiniteTransition(label = "trophyPulse")
    val trophyScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200),
            repeatMode = RepeatMode.Reverse
        ),
        label = "trophyScale"
    )

    Surface(
        color = DarkOverlay95,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onNavigateBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = Gold
                    )
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "投票結果",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "VOTE RESULTS · GAME COMPLETE",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                Icon(
                    imageVector = Icons.Default.EmojiEvents,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier
                        .size(28.dp)
                        .scale(trophyScale)
                )
                Spacer(modifier = Modifier.width(12.dp))
            }
            GoldDivider(withDiamond = true)
        }
    }
}

@Composable
private fun WinnerAnnouncementCard(
    winner: String?,
    winnerLabel: String
) {
    val cardShape = CutCornerShape(topEnd = 24.dp, bottomStart = 24.dp)

    // Shimmer animation for winner badge
    val infiniteTransition = rememberInfiniteTransition(label = "winnerShimmer")
    val shimmerOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerOffset"
    )

    // Trophy animation
    val trophyScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "trophyScale"
    )

    Card(
        colors = CardDefaults.cardColors(containerColor = Gold.copy(alpha = 0.12f)),
        shape = cardShape,
        modifier = Modifier.border(
            width = 2.dp,
            brush = Brush.linearGradient(listOf(Gold, Gold.copy(alpha = 0.5f), Gold)),
            shape = cardShape
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Trophy with animation
            Box(
                modifier = Modifier
                    .size(64.dp)
                    .scale(trophyScale)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(Gold.copy(alpha = 0.3f), Color.Transparent)
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.EmojiEvents,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(48.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "☆ THE VOTE HAS CONCLUDED ☆",
                color = GoldAccent,
                fontSize = 10.sp,
                letterSpacing = 3.sp
            )
            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "最終決議",
                color = Gold,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )

            Spacer(modifier = Modifier.height(8.dp))
            GoldDivider(modifier = Modifier.fillMaxWidth(0.5f), withDiamond = true)
            Spacer(modifier = Modifier.height(12.dp))

            if (winner != null) {
                val badgeShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)
                Box(
                    modifier = Modifier
                        .clip(badgeShape)
                        .background(
                            Brush.horizontalGradient(
                                colors = listOf(
                                    Gold.copy(alpha = 0.8f + shimmerOffset * 0.2f),
                                    Gold,
                                    Gold.copy(alpha = 0.8f + (1f - shimmerOffset) * 0.2f)
                                )
                            )
                        )
                        .border(1.dp, Gold, badgeShape)
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "選項 $winner",
                            color = DarkBackground,
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Serif
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "◆",
                            color = DarkBackground,
                            fontSize = 12.sp
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = winnerLabel,
                            color = DarkBackground,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            } else {
                Text(
                    text = "⏳ 投票尚未完成",
                    color = TextMuted,
                    fontSize = 16.sp,
                    fontStyle = FontStyle.Italic
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "「歷史將銘記這一刻」",
                color = TextSecondary,
                fontSize = 14.sp,
                fontStyle = FontStyle.Italic,
                fontFamily = FontFamily.Serif
            )
        }
    }
}

@Composable
private fun VoteResultsSummaryCard(
    round1Percentages: Map<String, Float>,
    round2Results: Map<String, Int>
) {
    val cardShape = CutCornerShape(topEnd = 16.dp, bottomStart = 16.dp)

    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = cardShape,
        modifier = Modifier.border(1.dp, CardBorderGold, cardShape)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "◆", color = Gold, fontSize = 12.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        text = "投票統計",
                        color = Gold,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = "VOTING STATISTICS",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            GoldDivider(withDiamond = false)
            Spacer(modifier = Modifier.height(16.dp))

            // Round 1 Results
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "①", color = GoldAccent, fontSize = 14.sp)
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "第一輪投票（匿名）",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Spacer(modifier = Modifier.height(10.dp))

            round1Percentages.forEach { (option, percentage) ->
                VoteBar(
                    option = option,
                    percentage = percentage,
                    count = null
                )
                Spacer(modifier = Modifier.height(8.dp))
            }

            Spacer(modifier = Modifier.height(12.dp))
            GoldDivider(withDiamond = false)
            Spacer(modifier = Modifier.height(12.dp))

            // Round 2 Results
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "②", color = GoldAccent, fontSize = 14.sp)
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "第二輪投票（記名）",
                    color = TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Spacer(modifier = Modifier.height(10.dp))

            val totalVotes = round2Results.values.sum().toFloat().coerceAtLeast(1f)
            round2Results.forEach { (option, count) ->
                VoteBar(
                    option = option,
                    percentage = (count / totalVotes) * 100,
                    count = count
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun VoteBar(
    option: String,
    percentage: Float,
    count: Int?
) {
    val boxShape = CutCornerShape(topEnd = 6.dp, bottomStart = 6.dp)
    val barShape = CutCornerShape(topEnd = 4.dp, bottomStart = 4.dp)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        // Option badge
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(boxShape)
                .background(
                    Brush.radialGradient(
                        colors = listOf(DarkSurfaceVariant, DarkBackground)
                    )
                )
                .border(1.dp, GoldMuted, boxShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = option,
                color = Gold,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Progress bar
        Box(
            modifier = Modifier
                .weight(1f)
                .height(20.dp)
                .clip(barShape)
                .background(DarkSurfaceVariant)
                .border(1.dp, CardBorderGold.copy(alpha = 0.3f), barShape)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(percentage / 100f)
                    .fillMaxHeight()
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(Gold, GoldAccent)
                        )
                    )
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Percentage/count
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "${percentage.toInt()}%",
                color = Gold,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
            if (count != null) {
                Text(
                    text = "$count 票",
                    color = GoldAccent,
                    fontSize = 10.sp
                )
            }
        }
    }
}

@Composable
private fun PlayerResultCard(player: PlayerResult) {
    val cardShape = CutCornerShape(topEnd = 10.dp, bottomStart = 10.dp)
    val voteShape = CutCornerShape(topEnd = 8.dp, bottomStart = 8.dp)

    // Role color based on type
    val roleColor = when (player.roleType) {
        "worker" -> WorkerColor
        "factory" -> FactoryColor
        "luddite" -> LudditeColor
        "reformer" -> ReformerColor
        "mp" -> MPColor
        "king" -> GeorgeIIIColor
        else -> GoldMuted
    }

    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = cardShape,
        modifier = Modifier.border(1.dp, CardBorderGold, cardShape)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar with role color
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(roleColor, roleColor.copy(alpha = 0.6f))
                        )
                    )
                    .border(2.dp, Gold, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = player.nickname.firstOrNull()?.uppercase() ?: "?",
                    color = TextPrimary,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = player.nickname,
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold
                )
                player.roleType?.let { roleType ->
                    Text(
                        text = getRoleDisplayName(roleType),
                        color = GoldAccent,
                        fontSize = 11.sp
                    )
                }
            }

            // Vote indicator
            player.vote2?.let { vote ->
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(voteShape)
                        .background(Gold.copy(alpha = 0.2f))
                        .border(1.dp, Gold, voteShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = vote,
                        color = Gold,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                }
            }
        }
    }
}

@Composable
private fun EventHistoryCard(events: List<GameEventResponse>) {
    val cardShape = CutCornerShape(topEnd = 16.dp, bottomStart = 16.dp)

    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = cardShape,
        modifier = Modifier.border(1.dp, CardBorderGold, cardShape)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "⚡", fontSize = 18.sp)
                Spacer(modifier = Modifier.width(10.dp))
                Column {
                    Text(
                        text = "突發事件回顧",
                        color = Gold,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = "EVENT HISTORY",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            GoldDivider(withDiamond = false)
            Spacer(modifier = Modifier.height(16.dp))

            events.forEachIndexed { index, gameEvent ->
                Row(modifier = Modifier.fillMaxWidth()) {
                    // Timeline with connecting line
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.width(20.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .clip(CutCornerShape(3.dp))
                                .background(Gold)
                                .border(1.dp, GoldAccent, CutCornerShape(3.dp))
                        )
                        if (index < events.size - 1) {
                            Box(
                                modifier = Modifier
                                    .width(2.dp)
                                    .height(40.dp)
                                    .background(
                                        Brush.verticalGradient(
                                            colors = listOf(Gold, CardBorderGold)
                                        )
                                    )
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = gameEvent.event.title,
                            color = TextPrimary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = gameEvent.event.description,
                            color = TextSecondary,
                            fontSize = 12.sp,
                            lineHeight = 16.sp,
                            maxLines = 2
                        )
                    }
                }

                if (index < events.size - 1) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

private fun getRoleDisplayName(roleType: String): String {
    return when (roleType) {
        "worker" -> "紡織工人"
        "factory" -> "工廠主"
        "luddite" -> "盧德派"
        "reformer" -> "改革者"
        "mp" -> "議員"
        "king" -> "國王喬治三世"
        else -> roleType
    }
}
