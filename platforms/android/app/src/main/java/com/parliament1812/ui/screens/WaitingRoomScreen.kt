package com.parliament1812.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.models.Player
import com.parliament1812.ui.components.*
import com.parliament1812.ui.components.CharacterPortraitSmall
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.RoomViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WaitingRoomScreen(
    roomCode: String,
    isHost: Boolean,
    onNavigateToNFCScan: () -> Unit,
    onNavigateToGame: () -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: RoomViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()

    // Refresh players when screen loads
    LaunchedEffect(roomCode) {
        viewModel.refreshPlayers(roomCode)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Background Image
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
            particleCount = 12
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
            // Top Header Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DarkOverlay95)
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
                        text = "等候大廳",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "WAITING HALL",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                if (isHost) {
                    IconButton(onClick = { /* TODO: Host settings */ }) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "設定",
                            tint = Gold
                        )
                    }
                }
            }

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.height(24.dp))

                // Room Code Section
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "◇", color = Gold, fontSize = 12.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = "皇家通行證",
                            color = TextSecondary,
                            fontSize = 12.sp
                        )
                        Text(
                            text = "Royal Pass Code",
                            color = TextMuted,
                            fontSize = 10.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Room Code Card
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = DarkOverlay95
                    ),
                    shape = RoundedCornerShape(8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, CardBorderGold, RoundedCornerShape(8.dp))
                        .clickable { copyToClipboard(context, roomCode) }
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = roomCode,
                            fontSize = 40.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Serif,
                            color = Gold,
                            letterSpacing = 12.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                TextButton(
                    onClick = { copyToClipboard(context, roomCode) }
                ) {
                    Icon(
                        imageVector = Icons.Default.ContentCopy,
                        contentDescription = null,
                        tint = GoldAccent,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "複製通行碼",
                        color = GoldAccent,
                        fontSize = 12.sp
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Decorative Divider
                GoldDivider(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    withDiamond = true
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Stats Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    StatItem(
                        label = "在席成員",
                        subLabel = "Present",
                        value = "${uiState.players.size}",
                        subValue = "/ 20"
                    )
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .height(60.dp)
                            .background(DividerGold)
                    )
                    StatItem(
                        label = "準備就緒",
                        subLabel = "Ready",
                        value = "${uiState.players.count { it.hasRole }}",
                        subValue = "/ ${uiState.players.size}"
                    )
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Members Section Title
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "◇", color = Gold, fontSize = 12.sp)
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = "國會議員名單",
                            color = TextPrimary,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "MEMBERS OF PARLIAMENT",
                            color = TextMuted,
                            fontSize = 10.sp,
                            letterSpacing = 2.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Player List
                if (uiState.players.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = Gold,
                            modifier = Modifier.size(32.dp),
                            strokeWidth = 2.dp
                        )
                    }
                } else {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        contentPadding = PaddingValues(horizontal = 4.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        items(uiState.players) { player ->
                            PlayerCard(
                                player = player,
                                isCurrentUser = player.id == uiState.currentPlayer?.id
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Claim Identity Button
                Button(
                    onClick = onNavigateToNFCScan,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Gold,
                        contentColor = DarkBackground
                    ),
                    shape = CutCornerShape(bottomEnd = 16.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Text(text = "☆", fontSize = 18.sp)
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = "領取身份令牌",
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 2.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Start Game Button (Host Only)
                if (isHost) {
                    val allPlayersReady = uiState.players.isNotEmpty() &&
                        uiState.players.all { it.hasRole }

                    OutlinedButton(
                        onClick = onNavigateToGame,
                        enabled = allPlayersReady,
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = if (allPlayersReady) Gold else TextMuted
                        ),
                        border = BorderStroke(
                            width = 1.dp,
                            color = if (allPlayersReady) Gold else GoldMuted.copy(alpha = 0.5f)
                        ),
                        shape = CutCornerShape(topStart = 8.dp, bottomEnd = 8.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                    ) {
                        Text(
                            text = if (allPlayersReady) "開始遊戲" else "等待所有玩家就緒...",
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 1.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                }

                // Status Text
                Text(
                    text = "已有 ${uiState.players.size} 位議員就座",
                    color = TextMuted,
                    fontSize = 12.sp
                )

                Spacer(modifier = Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun StatItem(
    label: String,
    subLabel: String,
    value: String,
    subValue: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(horizontal = 16.dp)
    ) {
        Text(
            text = label,
            color = TextSecondary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )
        Text(
            text = subLabel,
            color = TextMuted,
            fontSize = 10.sp,
            letterSpacing = 2.sp
        )
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            verticalAlignment = Alignment.Bottom
        ) {
            Text(
                text = value,
                color = Gold,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
            Text(
                text = subValue,
                color = TextMuted,
                fontSize = 16.sp,
                modifier = Modifier.padding(bottom = 6.dp, start = 2.dp)
            )
        }
    }
}

@Composable
private fun PlayerCard(
    player: Player,
    isCurrentUser: Boolean
) {
    val cardShape = CutCornerShape(topEnd = 12.dp, bottomStart = 12.dp)

    // Pulsing animation for current user
    val infiniteTransition = rememberInfiniteTransition(label = "playerPulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isCurrentUser) 1.02f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )

    Card(
        colors = CardDefaults.cardColors(
            containerColor = if (isCurrentUser) Gold.copy(alpha = 0.15f) else DarkOverlay95
        ),
        shape = cardShape,
        modifier = Modifier
            .width(115.dp)
            .scale(pulseScale)
            .border(
                width = if (isCurrentUser) 2.dp else 1.dp,
                brush = if (isCurrentUser) {
                    Brush.linearGradient(listOf(Gold, Gold.copy(alpha = 0.5f), Gold))
                } else {
                    Brush.linearGradient(listOf(CardBorderGold, CardBorderGold))
                },
                shape = cardShape
            )
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Avatar with role portrait
            if (player.hasRole && player.roleType != null) {
                CharacterPortraitSmall(
                    roleType = player.roleType ?: "",
                    size = 48.dp,
                    showBorder = true
                )
            } else {
                // Default avatar for players without role
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.radialGradient(
                                colors = listOf(GoldMuted.copy(alpha = 0.5f), GoldMuted.copy(alpha = 0.3f))
                            )
                        )
                        .border(2.dp, CardBorderGold, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = player.nickname.take(1).uppercase(),
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Host badge with crown
            if (player.isHost) {
                Text(
                    text = "👑 HOST",
                    fontSize = 9.sp,
                    letterSpacing = 1.sp,
                    color = Gold
                )
            }

            Text(
                text = player.nickname,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                textAlign = TextAlign.Center,
                maxLines = 1
            )

            if (player.hasRole) {
                Text(
                    text = player.displayRoleName,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium,
                    color = GoldAccent
                )
            } else {
                Text(
                    text = "⏳ 待認證",
                    fontSize = 10.sp,
                    color = TextMuted
                )
            }
        }
    }
}

private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("房間代碼", text)
    clipboard.setPrimaryClip(clip)
    Toast.makeText(context, "已複製到剪貼簿", Toast.LENGTH_SHORT).show()
}
