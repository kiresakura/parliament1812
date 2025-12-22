package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.remote.EventResponse
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.HostPanelViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HostPanelScreen(
    roomCode: String,
    playerId: String,
    onNavigateBack: () -> Unit,
    viewModel: HostPanelViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showTimerDialog by remember { mutableStateOf(false) }
    var showEventDialog by remember { mutableStateOf(false) }

    // Initialize
    LaunchedEffect(roomCode, playerId) {
        viewModel.initialize(roomCode, playerId)
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

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Header
            HostPanelHeader(
                roomCode = roomCode,
                playerCount = uiState.playerCount,
                onNavigateBack = onNavigateBack,
                onRefresh = { viewModel.refreshData() }
            )

            // Content
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item { Spacer(modifier = Modifier.height(8.dp)) }

                // Current Status Card
                item {
                    CurrentStatusCard(
                        currentPhase = uiState.currentPhase,
                        timerEndAt = uiState.timerEndAt
                    )
                }

                // Phase Controls
                item {
                    PhaseControlCard(
                        currentPhase = uiState.currentPhase,
                        isLoading = uiState.isChangingPhase,
                        onChangePhase = { viewModel.changePhase(it) }
                    )
                }

                // Timer Controls
                item {
                    TimerControlCard(
                        isLoading = uiState.isSettingTimer,
                        onSetTimer = { showTimerDialog = true }
                    )
                }

                // Event Controls
                item {
                    EventControlCard(
                        availableEvents = uiState.availableEvents,
                        isLoading = uiState.isTriggeringEvent,
                        onTriggerEvent = { viewModel.triggerEvent(it) },
                        onTriggerRandom = { viewModel.triggerRandomEvent() },
                        onShowAll = { showEventDialog = true }
                    )
                }

                // Triggered Event Display
                uiState.triggeredEvent?.let { event ->
                    item {
                        TriggeredEventCard(
                            event = event,
                            onDismiss = { viewModel.clearTriggeredEvent() }
                        )
                    }
                }

                item { Spacer(modifier = Modifier.height(24.dp)) }
            }
        }

        // Success Snackbar
        uiState.successMessage?.let { message ->
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                action = {
                    TextButton(onClick = { viewModel.clearSuccessMessage() }) {
                        Text("關閉", color = Gold)
                    }
                },
                containerColor = Success.copy(alpha = 0.9f)
            ) {
                Text(message)
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

    // Timer Dialog
    if (showTimerDialog) {
        TimerDialog(
            onDismiss = { showTimerDialog = false },
            onConfirm = { seconds ->
                viewModel.setTimer(seconds)
                showTimerDialog = false
            }
        )
    }

    // Event Selection Dialog
    if (showEventDialog) {
        EventSelectionDialog(
            events = uiState.availableEvents,
            onDismiss = { showEventDialog = false },
            onSelect = { eventId ->
                viewModel.triggerEvent(eventId)
                showEventDialog = false
            }
        )
    }
}

@Composable
private fun HostPanelHeader(
    roomCode: String,
    playerCount: Int,
    onNavigateBack: () -> Unit,
    onRefresh: () -> Unit
) {
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
                        text = "主持人控制台",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "房間 $roomCode · $playerCount 位玩家",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                IconButton(onClick = onRefresh) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = "重新載入",
                        tint = Gold
                    )
                }

                Icon(
                    imageVector = Icons.Default.AdminPanelSettings,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(28.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
            }
            HorizontalDivider(color = DividerGold, thickness = 1.dp)
        }
    }
}

@Composable
private fun CurrentStatusCard(
    currentPhase: Int,
    timerEndAt: Long?
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "目前狀態",
                color = Gold,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 2.sp
            )
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "階段",
                        color = TextMuted,
                        fontSize = 12.sp
                    )
                    Text(
                        text = GamePhase.getPhaseName(currentPhase),
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "計時器",
                        color = TextMuted,
                        fontSize = 12.sp
                    )
                    Text(
                        text = if (timerEndAt != null) {
                            val remaining = (timerEndAt - System.currentTimeMillis()) / 1000
                            if (remaining > 0) {
                                val minutes = remaining / 60
                                val seconds = remaining % 60
                                String.format("%02d:%02d", minutes, seconds)
                            } else "已結束"
                        } else "未設定",
                        color = if (timerEndAt != null) Gold else TextMuted,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun PhaseControlCard(
    currentPhase: Int,
    isLoading: Boolean,
    onChangePhase: (Int) -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.SkipNext,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "階段控制",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp
                )
            }
            Spacer(modifier = Modifier.height(12.dp))

            // Quick phase buttons
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val keyPhases = listOf(
                    2 to "角色研究",
                    3 to "密謀",
                    4 to "辯論",
                    8 to "第一輪投票",
                    10 to "第二輪投票",
                    11 to "結果揭曉"
                )

                items(keyPhases) { (phase, name) ->
                    PhaseChip(
                        phase = phase,
                        name = name,
                        isSelected = currentPhase == phase,
                        isLoading = isLoading,
                        onClick = { onChangePhase(phase) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Next/Previous buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { if (currentPhase > 1) onChangePhase(currentPhase - 1) },
                    enabled = currentPhase > 1 && !isLoading,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = Gold
                    ),
                    border = BorderStroke(1.dp, GoldMuted)
                ) {
                    Icon(imageVector = Icons.Default.ArrowBack, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("上一階段")
                }

                Button(
                    onClick = { if (currentPhase < 12) onChangePhase(currentPhase + 1) },
                    enabled = currentPhase < 12 && !isLoading,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Gold,
                        contentColor = DarkBackground
                    )
                ) {
                    Text("下一階段")
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(imageVector = Icons.Default.ArrowForward, contentDescription = null)
                }
            }
        }
    }
}

@Composable
private fun PhaseChip(
    phase: Int,
    name: String,
    isSelected: Boolean,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    val backgroundColor = if (isSelected) Gold else DarkSurfaceVariant
    val textColor = if (isSelected) DarkBackground else TextSecondary

    Surface(
        modifier = Modifier.clickable(enabled = !isLoading) { onClick() },
        color = backgroundColor,
        shape = RoundedCornerShape(16.dp)
    ) {
        Text(
            text = name,
            color = textColor,
            fontSize = 12.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun TimerControlCard(
    isLoading: Boolean,
    onSetTimer: () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Timer,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "計時器控制",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp
                )
            }
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(
                    5 to "5分鐘",
                    10 to "10分鐘",
                    15 to "15分鐘",
                    30 to "30分鐘"
                ).forEach { (minutes, label) ->
                    TimerChip(
                        label = label,
                        isLoading = isLoading,
                        onClick = { /* Quick set will be handled via dialog */ }
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Button(
                onClick = onSetTimer,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Gold,
                    contentColor = DarkBackground
                )
            ) {
                Icon(imageVector = Icons.Default.Timer, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("設定計時器")
            }
        }
    }
}

@Composable
private fun TimerChip(
    label: String,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    Surface(
        modifier = Modifier.clickable(enabled = !isLoading) { onClick() },
        color = DarkSurfaceVariant,
        shape = RoundedCornerShape(16.dp)
    ) {
        Text(
            text = label,
            color = TextSecondary,
            fontSize = 12.sp,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun EventControlCard(
    availableEvents: List<EventResponse>,
    isLoading: Boolean,
    onTriggerEvent: (String) -> Unit,
    onTriggerRandom: () -> Unit,
    onShowAll: () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Bolt,
                    contentDescription = null,
                    tint = Gold,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "突發事件",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "${availableEvents.size} 個可用",
                    color = TextMuted,
                    fontSize = 12.sp
                )
            }
            Spacer(modifier = Modifier.height(12.dp))

            // Quick event previews
            if (availableEvents.isNotEmpty()) {
                availableEvents.take(3).forEach { event ->
                    EventPreviewItem(
                        event = event,
                        isLoading = isLoading,
                        onTrigger = { onTriggerEvent(event.id) }
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }
            } else {
                Text(
                    text = "目前沒有可用的事件",
                    color = TextMuted,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onShowAll,
                    enabled = availableEvents.isNotEmpty() && !isLoading,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Gold),
                    border = BorderStroke(1.dp, GoldMuted)
                ) {
                    Text("查看全部")
                }

                Button(
                    onClick = onTriggerRandom,
                    enabled = !isLoading,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Gold,
                        contentColor = DarkBackground
                    )
                ) {
                    Icon(imageVector = Icons.Default.Casino, contentDescription = null)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("隨機抽取")
                }
            }
        }
    }
}

@Composable
private fun EventPreviewItem(
    event: EventResponse,
    isLoading: Boolean,
    onTrigger: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(4.dp))
            .background(DarkSurfaceVariant)
            .clickable(enabled = !isLoading) { onTrigger() }
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = event.title,
                color = TextPrimary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = "嚴重度: ${event.severity}",
                color = TextMuted,
                fontSize = 11.sp
            )
        }
        Icon(
            imageVector = Icons.Default.PlayArrow,
            contentDescription = "觸發",
            tint = Gold
        )
    }
}

@Composable
private fun TriggeredEventCard(
    event: EventResponse,
    onDismiss: () -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Success.copy(alpha = 0.1f)),
        shape = RoundedCornerShape(8.dp),
        border = CardDefaults.outlinedCardBorder().copy(
            brush = Brush.horizontalGradient(listOf(Success, Success.copy(alpha = 0.5f)))
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Success,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "事件已觸發",
                        color = Success,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "關閉",
                        tint = TextMuted
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = event.title,
                color = TextPrimary,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = event.description,
                color = TextSecondary,
                fontSize = 13.sp,
                lineHeight = 18.sp
            )
        }
    }
}

@Composable
private fun TimerDialog(
    onDismiss: () -> Unit,
    onConfirm: (Int) -> Unit
) {
    var selectedMinutes by remember { mutableIntStateOf(10) }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DarkSurface,
        title = {
            Text(
                text = "設定計時器",
                color = Gold,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = "選擇計時時間（分鐘）",
                    color = TextSecondary
                )
                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    listOf(5, 10, 15, 20, 25, 30).forEach { minutes ->
                        Surface(
                            modifier = Modifier.clickable { selectedMinutes = minutes },
                            color = if (selectedMinutes == minutes) Gold else DarkSurfaceVariant,
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text(
                                text = "$minutes",
                                color = if (selectedMinutes == minutes) DarkBackground else TextSecondary,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(12.dp)
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(selectedMinutes * 60) },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Gold,
                    contentColor = DarkBackground
                )
            ) {
                Text("確認")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消", color = TextMuted)
            }
        }
    )
}

@Composable
private fun EventSelectionDialog(
    events: List<EventResponse>,
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DarkSurface,
        title = {
            Text(
                text = "選擇事件",
                color = Gold,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(events) { event ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(event.id) },
                        colors = CardDefaults.cardColors(containerColor = DarkSurfaceVariant)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(
                                text = event.title,
                                color = TextPrimary,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = event.description,
                                color = TextSecondary,
                                fontSize = 12.sp,
                                maxLines = 2
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Row {
                                Text(
                                    text = "嚴重度: ${event.severity}",
                                    color = TextMuted,
                                    fontSize = 11.sp
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "效果: ${event.effectType}",
                                    color = TextMuted,
                                    fontSize = 11.sp
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("關閉", color = TextMuted)
            }
        }
    )
}
