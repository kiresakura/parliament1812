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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
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
import androidx.compose.foundation.Canvas
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
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
    playerId: String = "",
    onNavigateToNFCScan: () -> Unit,
    onNavigateToGame: () -> Unit,
    onNavigateBack: () -> Unit,
    viewModel: RoomViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()

    // Refresh players when screen loads and periodically
    LaunchedEffect(roomCode) {
        viewModel.refreshPlayers(roomCode)
        // Periodic refresh every 3 seconds as backup for WebSocket
        while (true) {
            kotlinx.coroutines.delay(3000)
            viewModel.refreshPlayers(roomCode)
        }
    }

    FogOfWarOverlay(modifier = Modifier.fillMaxSize()) {
        // Base muted background (darker for atmosphere)
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF15100B)) // Very dark brown/black
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Top Header Bar - styled with Victorian logic
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Back button
                TextButton(
                    onClick = {
                        if (!isHost) {
                            viewModel.leaveRoom { onNavigateBack() }
                        } else {
                            viewModel.disconnect()
                            onNavigateBack()
                        }
                    },
                    colors = ButtonDefaults.textButtonColors(contentColor = GoldMuted)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "返回",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "退出議事廳",
                        fontFamily = FontFamily.Serif,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

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
                    .paperSurface(alpha = 0.08f) // Apply paper texture to the scrollable content area
                    .padding(horizontal = 24.dp), // Increased padding for clearer layout
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Victorian Room Code Display
                VictorianRoomCodeDisplay(
                    roomCode = roomCode,
                    onCopyClick = { copyToClipboard(context, roomCode) }
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Stats Row with Gold Dividers
                GoldDivider(withDiamond = true)
                Spacer(modifier = Modifier.height(16.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    VictorianStatDisplay(
                        label = "在席議員",
                        value = "${uiState.players.size}",
                        subConfig = "/ 20"
                    )
                    VictorianStatDisplay(
                        label = "準備進度",
                        value = "${uiState.players.count { it.isReady }}",
                        subConfig = "/ ${uiState.players.size}"
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                GoldDivider(withDiamond = true)

                Spacer(modifier = Modifier.height(32.dp))

                // Members Section Title
                VictorianSectionHeader(
                    title = "國會議員名單",
                    subtitle = "MEMBERS OF PARLIAMENT",
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Calculate effective player ID early so it can be used for both
                // player card highlighting and action buttons
                val effectivePlayerId = if (playerId.isNotEmpty()) playerId else uiState.currentPlayer?.id

                // Player List
                if (uiState.players.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(150.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = Gold,
                            modifier = Modifier.size(32.dp),
                            strokeWidth = 2.dp
                        )
                    }
                } else {
                    // 2-column grid using VictorianOvalPlayerCard
                    // Note: Nested scrolling with LazyVerticalGrid inside Column + verticalScroll is tricky.
                    // For a limited number of items (max 20), FlowRow or a simple Column of Rows is better/safer,
                    // but since we want grid style, we can calculate height or use a non-lazy grid approach.
                    // However, let's stick to LazyVerticalGrid with fixed height for now as per original code.
                    
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        contentPadding = PaddingValues(vertical = 8.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 600.dp) // Cap height
                    ) {
                        items(
                            items = uiState.players,
                            key = { it.id }
                        ) { player ->
                            VictorianOvalPlayerCard(
                                nickname = player.nickname,
                                roleType = player.roleType,
                                isHost = player.isHost,
                                isReady = player.isReady,
                                isCurrentUser = player.id == effectivePlayerId
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Action Buttons Area
                // Use playerId parameter directly to find current player from list
                // This works even when ViewModel state is not synced after navigation
                val currentPlayerFromList = effectivePlayerId?.let { id ->
                    uiState.players.find { it.id == id }
                }
                val currentPlayerHasRole = currentPlayerFromList?.hasRole == true
                val currentPlayerIsReady = currentPlayerFromList?.isReady == true

                // Claim Identity Button
                if (!currentPlayerHasRole) {
                    RegencyStyledButton(
                        text = "領取身份令牌",
                        onClick = onNavigateToNFCScan,
                        icon = "⚜",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Ready Button
                if (currentPlayerHasRole && !isHost) {
                    RegencyStyledButton(
                        text = if (currentPlayerIsReady) "已簽署與準備" else "簽署就緒",
                        onClick = {
                            currentPlayerFromList?.let { player ->
                                viewModel.setReady(player.id, !currentPlayerIsReady)
                            }
                        },
                        isPrimary = !currentPlayerIsReady, // If ready, show as secondary/pressed state visually? Or just keep primary. Let's keep primary but maybe change text.
                        // Actually RegencyStyledButton logic: isPrimary -> Gold bg. !isPrimary -> Transparent with border.
                        // If ready, we might want it to look "Activated" (Green?). 
                        // The component doesn't support green easily. Let's stick to Gold logic or create a custom one.
                        // For now, let's use isPrimary=true for action "Set Ready", and maybe isPrimary=false (outlined) if already ready?
                        // "Click to unready" -> isPrimary = false.
                        isLoading = uiState.isSettingReady,
                        icon = if (currentPlayerIsReady) "✓" else "✎",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                }

                // Host Actions
                val allPlayersReady = uiState.players.isNotEmpty() &&
                    uiState.players.all { it.hasRole && it.isReady }

                // Debug logging
                android.util.Log.d("WaitingRoom", "=== WaitingRoomScreen Debug ===")
                android.util.Log.d("WaitingRoom", "isHost=$isHost, roomCode=$roomCode, playerId=$playerId")
                android.util.Log.d("WaitingRoom", "Players: ${uiState.players.size}, allPlayersReady: $allPlayersReady")
                android.util.Log.d("WaitingRoom", "currentPlayerHasRole=$currentPlayerHasRole, currentPlayerIsReady=$currentPlayerIsReady")
                uiState.players.forEach { p ->
                    android.util.Log.d("WaitingRoom", "  Player ${p.nickname}: hasRole=${p.hasRole}, roleType=${p.roleType}, isReady=${p.isReady}, id=${p.id}")
                }
                android.util.Log.d("WaitingRoom", "================================")

                if (isHost) {
                    android.util.Log.d("WaitingRoom", ">>> Rendering HOST controls <<<")
                } else {
                    android.util.Log.d("WaitingRoom", ">>> Rendering NON-HOST view <<<")
                }

                if (isHost) {
                    // Host Ready (as a player)
                    if (currentPlayerHasRole) {
                        RegencyStyledButton(
                            text = if (currentPlayerIsReady) "議長已就緒" else "議長簽署",
                            onClick = {
                                currentPlayerFromList?.let { player ->
                                    viewModel.setReady(player.id, !currentPlayerIsReady)
                                }
                            },
                            isPrimary = !currentPlayerIsReady,
                            isLoading = uiState.isSettingReady,
                            icon = "♔",
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                    }

                    // Start Game - 調用 API 開始遊戲，成功後導航
                    android.util.Log.d("WaitingRoom", "Button state: enabled=${allPlayersReady && !uiState.isLoading}, allPlayersReady=$allPlayersReady, isLoading=${uiState.isLoading}")
                    RegencyStyledButton(
                        text = "開啟國會議程",
                        onClick = {
                            android.util.Log.d("WaitingRoom", "Start Game button clicked!")
                            viewModel.startGame { onNavigateToGame() }
                        },
                        enabled = allPlayersReady && !uiState.isLoading,
                        isLoading = uiState.isLoading,
                        icon = "⚔",
                        modifier = Modifier.fillMaxWidth()
                    )
                    if (!allPlayersReady) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "等待所有成員簽署就緒...",
                            color = GoldMuted,
                            fontSize = 12.sp,
                            fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                        )
                    }
                } else {
                    // Non-host waiting message
                    if (currentPlayerIsReady) {
                        Text(
                            text = "等待議長宣佈開議...",
                            color = Gold,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
}

/**
 * Victorian Room Code Display - Styled like a royal decree header
 */
@Composable
private fun VictorianRoomCodeDisplay(
    roomCode: String,
    onCopyClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp),
        contentAlignment = Alignment.Center
    ) {
        // Decorative background (like a wax sealed letter header)
        Canvas(modifier = Modifier.fillMaxSize()) {
            val width = size.width
            val height = size.height
            val path = Path().apply {
                moveTo(0f, 0f)
                lineTo(width, 0f)
                lineTo(width, height * 0.8f)
                quadraticBezierTo(width / 2, height, 0f, height * 0.8f)
                close()
            }
            
            drawPath(
                path = path,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        DarkSurfaceVariant,
                        DarkSurface
                    )
                )
            )
            
            drawPath(
                path = path,
                brush = Brush.linearGradient(
                    colors = listOf(GoldMuted, Gold, GoldMuted)
                ),
                style = Stroke(width = 2.dp.toPx())
            )
        }
        
        // Content
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(bottom = 16.dp)
        ) {
            Text(
                text = "ROYAL DECREE",
                fontSize = 10.sp,
                color = GoldMuted,
                letterSpacing = 4.sp,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    painter = painterResource(id = android.R.drawable.ic_menu_compass), // Placeholder if custom not avail, or use vector
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(16.dp) // Temporary placeholder
                )
                Text(
                    text = " 議事廳代碼 ",
                    fontSize = 14.sp,
                    color = TextSecondary,
                    fontFamily = FontFamily.Serif
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            
            // Room Code with Copy interaction
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .clickable { onCopyClick() }
                    .background(Gold.copy(alpha = 0.1f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 12.dp, vertical = 4.dp)
            ) {
                Text(
                    text = roomCode,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.ExtraBold,
                    fontFamily = FontFamily.Serif,
                    color = Gold,
                    letterSpacing = 6.sp
                )
                Spacer(modifier = Modifier.width(12.dp))
                Icon(
                    imageVector = Icons.Default.ContentCopy,
                    contentDescription = "複製",
                    tint = Gold.copy(alpha = 0.7f),
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

/**
 * Victorian Stat Display - Text-based stat with serif fonts
 */
@Composable
private fun VictorianStatDisplay(
    label: String,
    value: String,
    subConfig: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = label,
            color = GoldMuted,
            fontSize = 12.sp,
            fontFamily = FontFamily.Serif
        )
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = value,
                color = Gold,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
            Text(
                text = subConfig,
                color = TextMuted,
                fontSize = 14.sp,
                modifier = Modifier.padding(bottom = 6.dp, start = 4.dp)
            )
        }
    }
}


// Helper function to get role display name (Chinese)
private fun getRoleDisplayName(roleType: String): String {
    return when (roleType.lowercase()) {
        "worker" -> "紡織工人"
        "factory_owner", "factory" -> "工廠主"
        "luddite" -> "盧德派"
        "reformer" -> "改革者"
        "mp" -> "議員"
        "george_iii", "king" -> "喬治三世"
        else -> roleType
    }
}

// Helper function to get role English name
private fun getRoleEnglishName(roleType: String): String? {
    return when (roleType.lowercase()) {
        "worker" -> "Textile Worker"
        "factory_owner", "factory" -> "Factory Owner"
        "luddite" -> "Luddite"
        "reformer" -> "Reformer"
        "mp" -> "Member of Parliament"
        "george_iii", "king" -> "King George III"
        else -> null
    }
}

private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("房間代碼", text)
    clipboard.setPrimaryClip(clip)
    Toast.makeText(context, "已複製到剪貼簿", Toast.LENGTH_SHORT).show()
}
