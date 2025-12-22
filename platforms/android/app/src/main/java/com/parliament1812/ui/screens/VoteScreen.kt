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
import com.parliament1812.data.remote.VoteOption
import com.parliament1812.ui.components.*
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.VoteViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoteScreen(
    roomCode: String,
    playerId: String,
    voteRound: Int,
    onNavigateBack: () -> Unit,
    onVoteComplete: () -> Unit,
    viewModel: VoteViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Load vote options and status
    LaunchedEffect(roomCode, voteRound) {
        viewModel.loadVoteData(roomCode, playerId, voteRound)
    }

    // Navigate back after successful vote
    LaunchedEffect(uiState.voteSubmitted) {
        if (uiState.voteSubmitted) {
            onVoteComplete()
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
            // Header
            VoteHeader(
                voteRound = voteRound,
                onNavigateBack = onNavigateBack
            )

            // Content
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item { Spacer(modifier = Modifier.height(8.dp)) }

                // Vote Info Card
                item {
                    VoteInfoCard(voteRound = voteRound)
                }

                // Progress indicator
                item {
                    VoteProgressCard(
                        votedCount = uiState.votedCount,
                        totalPlayers = uiState.totalPlayers,
                        progress = uiState.progress
                    )
                }

                // Already voted message
                if (uiState.hasVoted) {
                    item {
                        AlreadyVotedCard(choice = uiState.myChoice)
                    }
                }

                // Vote Options
                if (!uiState.hasVoted) {
                    item {
                        Text(
                            text = "請選擇你的立場",
                            color = Gold,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 2.sp,
                            modifier = Modifier.padding(vertical = 8.dp)
                        )
                    }

                    items(uiState.options) { option ->
                        VoteOptionCard(
                            option = option,
                            isSelected = uiState.selectedChoice == option.key,
                            onSelect = { viewModel.selectOption(option.key) }
                        )
                    }

                    // Submit Button
                    item {
                        Spacer(modifier = Modifier.height(20.dp))

                        GoldDivider(modifier = Modifier.fillMaxWidth())

                        Spacer(modifier = Modifier.height(20.dp))

                        Button(
                            onClick = { viewModel.submitVote(roomCode, playerId, voteRound) },
                            enabled = uiState.selectedChoice != null && !uiState.isLoading,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(56.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = Gold,
                                contentColor = DarkBackground,
                                disabledContainerColor = GoldMuted.copy(alpha = 0.3f),
                                disabledContentColor = TextMuted
                            ),
                            shape = CutCornerShape(bottomEnd = 16.dp)
                        ) {
                            if (uiState.isLoading) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(22.dp),
                                    color = DarkBackground,
                                    strokeWidth = 2.dp
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.Default.HowToVote,
                                    contentDescription = null,
                                    modifier = Modifier.size(22.dp)
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = "☆ 確認投票",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 17.sp,
                                    letterSpacing = 2.sp
                                )
                            }
                        }
                    }
                }

                // Results (for round 1 percentage, round 2 full results)
                if (uiState.showResults) {
                    item {
                        VoteResultsCard(
                            voteRound = voteRound,
                            percentages = uiState.percentages,
                            playerVotes = uiState.playerVotes
                        )
                    }
                }

                // Error message
                uiState.error?.let { error ->
                    item {
                        val errorShape = CutCornerShape(topStart = 8.dp, bottomEnd = 8.dp)
                        Card(
                            colors = CardDefaults.cardColors(containerColor = Error.copy(alpha = 0.1f)),
                            shape = errorShape,
                            modifier = Modifier.border(1.dp, Error.copy(alpha = 0.5f), errorShape)
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(text = "⚠", fontSize = 16.sp)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = error,
                                    color = Error,
                                    textAlign = TextAlign.Start,
                                    modifier = Modifier.weight(1f)
                                )
                            }
                        }
                    }
                }

                item { Spacer(modifier = Modifier.height(24.dp)) }
            }
        }
    }
}

@Composable
private fun VoteHeader(
    voteRound: Int,
    onNavigateBack: () -> Unit
) {
    // Pulsing animation for vote icon
    val infiniteTransition = rememberInfiniteTransition(label = "voteIconPulse")
    val iconScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "iconScale"
    )

    Surface(
        color = DarkOverlay95,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 8.dp),
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
                        text = if (voteRound == 1) "第一輪投票" else "最終投票",
                        color = Gold,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = if (voteRound == 1) "FIRST VOTE - ANONYMOUS" else "FINAL VOTE - PUBLIC",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                Icon(
                    imageVector = Icons.Default.HowToVote,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier
                        .size(32.dp)
                        .scale(iconScale)
                )
                Spacer(modifier = Modifier.width(12.dp))
            }
            GoldDivider(modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
private fun VoteInfoCard(voteRound: Int) {
    val cardShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)

    Card(
        colors = CardDefaults.cardColors(containerColor = DarkOverlay95),
        shape = cardShape,
        modifier = Modifier.border(1.dp, CardBorderGold, cardShape)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "◇", color = Gold, fontSize = 12.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        text = "投票說明",
                        color = Gold,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "VOTING INSTRUCTIONS",
                        color = TextMuted,
                        fontSize = 9.sp,
                        letterSpacing = 1.sp
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = if (voteRound == 1) {
                    "這是第一輪匿名投票。投票結果只會顯示各選項的百分比，不會公開個人選擇。"
                } else {
                    "這是最終記名投票。投票結束後，每個人的選擇都會公開揭曉。"
                },
                color = TextSecondary,
                fontSize = 14.sp,
                lineHeight = 20.sp
            )
        }
    }
}

@Composable
private fun VoteProgressCard(
    votedCount: Int,
    totalPlayers: Int,
    progress: Float
) {
    val cardShape = CutCornerShape(topStart = 8.dp, bottomEnd = 8.dp)

    Card(
        colors = CardDefaults.cardColors(containerColor = DarkOverlay95),
        shape = cardShape,
        modifier = Modifier.border(1.dp, CardBorderGold, cardShape)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "投票進度",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    Text(
                        text = "VOTE PROGRESS",
                        color = TextMuted,
                        fontSize = 9.sp,
                        letterSpacing = 1.sp
                    )
                }
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = "$votedCount",
                        color = Gold,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = " / $totalPlayers",
                        color = TextMuted,
                        fontSize = 14.sp,
                        modifier = Modifier.padding(bottom = 4.dp)
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(10.dp)
                    .clip(CutCornerShape(topEnd = 4.dp, bottomStart = 4.dp))
                    .background(DarkSurfaceVariant)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(progress)
                        .fillMaxHeight()
                        .background(
                            Brush.horizontalGradient(
                                listOf(Gold, Gold.copy(alpha = 0.7f))
                            )
                        )
                )
            }
        }
    }
}

@Composable
private fun AlreadyVotedCard(choice: String?) {
    val cardShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)

    // Subtle shimmer
    val infiniteTransition = rememberInfiniteTransition(label = "votedShimmer")
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
        colors = CardDefaults.cardColors(containerColor = Success.copy(alpha = shimmerAlpha)),
        shape = cardShape,
        modifier = Modifier.border(
            width = 2.dp,
            brush = Brush.linearGradient(listOf(Success, Success.copy(alpha = 0.5f), Success)),
            shape = cardShape
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = "✓", color = Success, fontSize = 28.sp)
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = "你已完成投票",
                    color = Success,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                choice?.let {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "你選擇了選項 $it",
                        color = TextSecondary,
                        fontSize = 13.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun VoteOptionCard(
    option: VoteOption,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    val cardShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)

    // Selection animation
    val infiniteTransition = rememberInfiniteTransition(label = "optionPulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isSelected) 1.02f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .scale(pulseScale)
            .clickable { onSelect() }
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                brush = if (isSelected) {
                    Brush.linearGradient(listOf(Gold, Gold.copy(alpha = 0.7f), Gold))
                } else {
                    Brush.linearGradient(listOf(CardBorderGold, CardBorderGold))
                },
                shape = cardShape
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected) Gold.copy(alpha = 0.15f) else DarkOverlay95
        ),
        shape = cardShape
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Option Letter Badge
            val badgeShape = CutCornerShape(topEnd = 6.dp, bottomStart = 6.dp)
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(badgeShape)
                    .background(
                        if (isSelected) {
                            Brush.radialGradient(listOf(Gold, Gold.copy(alpha = 0.8f)))
                        } else {
                            Brush.radialGradient(listOf(DarkSurfaceVariant, DarkSurfaceVariant))
                        }
                    )
                    .border(
                        width = 1.dp,
                        color = if (isSelected) Gold else GoldMuted,
                        shape = badgeShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = option.key,
                    color = if (isSelected) DarkBackground else Gold,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = option.title,
                    color = if (isSelected) Gold else TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = option.description,
                    color = TextSecondary,
                    fontSize = 13.sp,
                    lineHeight = 18.sp
                )
            }

            if (isSelected) {
                Text(text = "✓", color = Gold, fontSize = 24.sp)
            }
        }
    }
}

@Composable
private fun VoteResultsCard(
    voteRound: Int,
    percentages: Map<String, Float>,
    playerVotes: List<Pair<String, String>>
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
                        text = "投票結果",
                        color = Gold,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                    Text(
                        text = if (voteRound == 1) "PERCENTAGE RESULTS" else "FINAL RESULTS",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            GoldDivider(withDiamond = false)
            Spacer(modifier = Modifier.height(16.dp))

            if (voteRound == 1) {
                // Show percentages only
                percentages.forEach { (option, percentage) ->
                    ResultBar(
                        option = option,
                        percentage = percentage
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                }
            } else {
                // Show full results with player names
                percentages.forEach { (option, percentage) ->
                    ResultBar(
                        option = option,
                        percentage = percentage
                    )
                    // Show players who voted for this option
                    val voters = playerVotes.filter { it.second == option }
                    if (voters.isNotEmpty()) {
                        Text(
                            text = "☞ ${voters.joinToString(", ") { it.first }}",
                            color = GoldAccent,
                            fontSize = 11.sp,
                            modifier = Modifier.padding(start = 48.dp, top = 4.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(14.dp))
                }
            }
        }
    }
}

@Composable
private fun ResultBar(
    option: String,
    percentage: Float
) {
    val boxShape = CutCornerShape(topEnd = 6.dp, bottomStart = 6.dp)
    val barShape = CutCornerShape(topEnd = 4.dp, bottomStart = 4.dp)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
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

        Column(modifier = Modifier.weight(1f)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(24.dp)
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
        }

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = "${percentage.toInt()}%",
            color = Gold,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Serif,
            modifier = Modifier.width(52.dp),
            textAlign = TextAlign.End
        )
    }
}
