package com.parliament1812.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.ui.components.*
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.RoomViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToWaitingRoom: (roomCode: String, isHost: Boolean, playerId: String) -> Unit,
    viewModel: RoomViewModel = hiltViewModel()
) {
    var nickname by remember { mutableStateOf("") }
    var roomCode by remember { mutableStateOf("") }
    var selectedTab by remember { mutableStateOf(0) } // 0 = Create, 1 = Join
    val focusManager = LocalFocusManager.current

    val uiState by viewModel.uiState.collectAsState()

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
                .background(DarkOverlay60)
        )

        // Hexagonal Pattern Overlay
        HexagonalPattern(
            modifier = Modifier.fillMaxSize(),
            hexSize = 50f,
            color = Gold.copy(alpha = 0.03f)
        )

        // Ambient Particles (candlelight dust effect)
        AmbientParticles(
            modifier = Modifier.fillMaxSize(),
            particleCount = 15
        )

        // Vignette Effect
        VignetteOverlay(
            modifier = Modifier.fillMaxSize(),
            intensity = 0.6f
        )

        // Corner Ornaments
        VictorianCornerOrnament(
            corner = Corner.TopLeft,
            modifier = Modifier.align(Alignment.TopStart),
            color = Gold.copy(alpha = 0.2f)
        )
        VictorianCornerOrnament(
            corner = Corner.TopRight,
            modifier = Modifier.align(Alignment.TopEnd),
            color = Gold.copy(alpha = 0.2f)
        )
        VictorianCornerOrnament(
            corner = Corner.BottomLeft,
            modifier = Modifier.align(Alignment.BottomStart),
            color = Gold.copy(alpha = 0.2f)
        )
        VictorianCornerOrnament(
            corner = Corner.BottomRight,
            modifier = Modifier.align(Alignment.BottomEnd),
            color = Gold.copy(alpha = 0.2f)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Top Header Bar
            TopHeaderBar()

            Spacer(modifier = Modifier.height(24.dp))

            // Logo Badge
            LogoBadge()

            Spacer(modifier = Modifier.height(16.dp))

            // Title Section
            TitleSection()

            Spacer(modifier = Modifier.height(32.dp))

            // Tab Selector
            TabSelector(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it }
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Form Card
            FormCard(
                selectedTab = selectedTab,
                nickname = nickname,
                roomCode = roomCode,
                onNicknameChange = { nickname = it.take(20) },
                onRoomCodeChange = { roomCode = it.uppercase().take(6) },
                isLoading = uiState.isLoading,
                onCreateRoom = {
                    viewModel.createRoom(nickname) { code, playerId ->
                        onNavigateToWaitingRoom(code, true, playerId)
                    }
                },
                onJoinRoom = {
                    viewModel.joinRoom(roomCode, nickname) { playerId ->
                        onNavigateToWaitingRoom(roomCode, false, playerId)
                    }
                },
                focusManager = focusManager
            )

            // Error Message
            uiState.error?.let { error ->
                Spacer(modifier = Modifier.height(16.dp))
                ErrorMessage(error)
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom Quote
            BottomQuote()

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun TopHeaderBar() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(DarkOverlay80)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Crown Icon placeholder
        Text(
            text = "◆",
            fontSize = 20.sp,
            color = Gold
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(
                text = "REGENCY ERA",
                color = Gold,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.sp
            )
            Text(
                text = "1812 • British Parliament",
                color = TextTertiary,
                fontSize = 11.sp,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
private fun LogoBadge() {
    // Pulsing animation for the badge
    val infiniteTransition = rememberInfiniteTransition(label = "logoPulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowAlpha"
    )

    Box(
        modifier = Modifier
            .size(100.dp)
            .scale(pulseScale),
        contentAlignment = Alignment.Center
    ) {
        // Outer glow ring
        Box(
            modifier = Modifier
                .size(100.dp)
                .border(
                    width = 1.dp,
                    brush = Brush.radialGradient(
                        colors = listOf(
                            Gold.copy(alpha = glowAlpha),
                            Color.Transparent
                        )
                    ),
                    shape = HexagonShape
                )
        )

        // Main badge
        Box(
            modifier = Modifier
                .size(80.dp)
                .border(2.dp, Gold, HexagonShape)
                .background(DarkOverlay80, HexagonShape)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "☆",
                color = Gold,
                fontSize = 32.sp
            )
        }
    }
}

// Simple hexagon-like shape using rounded corners
private val HexagonShape = RoundedCornerShape(8.dp)
private val EaseInOutSine = CubicBezierEasing(0.37f, 0f, 0.63f, 1f)

@Composable
private fun TitleSection() {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        // Year with shimmer effect
        Box {
            Text(
                text = "1812",
                style = MaterialTheme.typography.displayLarge,
                color = Gold,
                fontFamily = FontFamily.Serif
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Decorative divider above title
        GoldDivider(
            modifier = Modifier
                .width(200.dp)
                .padding(vertical = 8.dp),
            withDiamond = true
        )

        Text(
            text = "國會風雲",
            style = MaterialTheme.typography.headlineLarge,
            color = TextPrimary,
            fontFamily = FontFamily.Serif
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "PARLIAMENT DEBATES",
            color = TextTertiary,
            fontSize = 12.sp,
            letterSpacing = 4.sp,
            fontWeight = FontWeight.Medium
        )

        // Decorative divider below
        GoldDivider(
            modifier = Modifier
                .width(160.dp)
                .padding(top = 12.dp),
            withDiamond = false
        )
    }
}

@Composable
private fun TabSelector(
    selectedTab: Int,
    onTabSelected: (Int) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp)
    ) {
        // Create Tab
        TabButton(
            text = "建立房間",
            subText = "CREATE",
            isSelected = selectedTab == 0,
            onClick = { onTabSelected(0) },
            modifier = Modifier.weight(1f)
        )

        // Join Tab
        TabButton(
            text = "加入房間",
            subText = "JOIN",
            isSelected = selectedTab == 1,
            onClick = { onTabSelected(1) },
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun TabButton(
    text: String,
    subText: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor = if (isSelected) Gold else DarkOverlay80
    val textColor = if (isSelected) DarkBackground else Gold
    val borderColor = if (isSelected) Gold else Gold.copy(alpha = 0.3f)
    val tabShape = CutCornerShape(topStart = 8.dp, bottomEnd = 8.dp)

    // Selection indicator animation
    val selectionAlpha by animateFloatAsState(
        targetValue = if (isSelected) 1f else 0f,
        animationSpec = tween(200),
        label = "tabSelection"
    )

    Box(
        modifier = modifier
            .height(64.dp)
            .padding(horizontal = 4.dp)
            .border(1.dp, borderColor, tabShape)
            .background(backgroundColor, tabShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            // Selection indicator
            if (isSelected) {
                Text(
                    text = "▼",
                    color = textColor,
                    fontSize = 8.sp,
                    modifier = Modifier.alpha(selectionAlpha)
                )
                Spacer(modifier = Modifier.height(2.dp))
            } else {
                Spacer(modifier = Modifier.height(12.dp))
            }
            Text(
                text = text,
                color = textColor,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
            Text(
                text = subText,
                color = textColor.copy(alpha = 0.7f),
                fontSize = 10.sp,
                letterSpacing = 2.sp
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FormCard(
    selectedTab: Int,
    nickname: String,
    roomCode: String,
    onNicknameChange: (String) -> Unit,
    onRoomCodeChange: (String) -> Unit,
    isLoading: Boolean,
    onCreateRoom: () -> Unit,
    onJoinRoom: () -> Unit,
    focusManager: androidx.compose.ui.focus.FocusManager
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp)
    ) {
        // Nickname Label
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(text = "◇", color = Gold, fontSize = 12.sp)
            Spacer(modifier = Modifier.width(8.dp))
            Column {
                Text(
                    text = "您的暱稱",
                    color = TextSecondary,
                    fontSize = 12.sp
                )
                Text(
                    text = "Your Nickname",
                    color = TextMuted,
                    fontSize = 10.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Nickname Input
        RegencyTextField(
            value = nickname,
            onValueChange = onNicknameChange,
            placeholder = "輸入暱稱...",
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
            keyboardActions = KeyboardActions(
                onNext = { focusManager.moveFocus(FocusDirection.Down) }
            )
        )

        // Room Code Field (only for Join tab)
        if (selectedTab == 1) {
            Spacer(modifier = Modifier.height(16.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = "◇", color = Gold, fontSize = 12.sp)
                Spacer(modifier = Modifier.width(8.dp))
                Column {
                    Text(
                        text = "房間代碼",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                    Text(
                        text = "Room Code",
                        color = TextMuted,
                        fontSize = 10.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            RegencyTextField(
                value = roomCode,
                onValueChange = onRoomCodeChange,
                placeholder = "XXXXXX",
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Characters,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onDone = {
                        focusManager.clearFocus()
                        if (nickname.isNotBlank() && roomCode.length == 6) {
                            onJoinRoom()
                        }
                    }
                )
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Action Button
        RegencyButton(
            text = if (selectedTab == 0) "建立新會議" else "進入議事廳",
            onClick = if (selectedTab == 0) onCreateRoom else onJoinRoom,
            enabled = nickname.isNotBlank() && (selectedTab == 0 || roomCode.length == 6) && !isLoading,
            isLoading = isLoading
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RegencyTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = {
            Text(
                text = placeholder,
                color = TextMuted
            )
        },
        singleLine = true,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = Gold,
            unfocusedBorderColor = InputBorder,
            focusedContainerColor = DarkOverlay80,
            unfocusedContainerColor = DarkOverlay80,
            cursorColor = Gold,
            focusedTextColor = TextPrimary,
            unfocusedTextColor = TextPrimary
        ),
        shape = RoundedCornerShape(4.dp),
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
private fun RegencyButton(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean,
    isLoading: Boolean
) {
    val buttonShape = CutCornerShape(bottomEnd = 16.dp)

    Button(
        onClick = onClick,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = Gold,
            contentColor = DarkBackground,
            disabledContainerColor = Gold.copy(alpha = 0.3f),
            disabledContentColor = DarkBackground.copy(alpha = 0.5f)
        ),
        shape = buttonShape,
        modifier = Modifier
            .fillMaxWidth()
            .height(60.dp)
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(24.dp),
                color = DarkBackground,
                strokeWidth = 2.dp
            )
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "☆",
                    fontSize = 18.sp
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = text,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )
            }
        }
    }
}

@Composable
private fun ErrorMessage(error: String) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = Error.copy(alpha = 0.15f)
        ),
        shape = RoundedCornerShape(4.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp)
    ) {
        Text(
            text = error,
            color = Error,
            fontSize = 14.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        )
    }
}

@Composable
private fun BottomQuote() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Decorative element
        Text(
            text = "· · · ☆ · · ·",
            color = Gold.copy(alpha = 0.5f),
            fontSize = 12.sp,
            letterSpacing = 4.sp
        )
        Spacer(modifier = Modifier.height(12.dp))
        VictorianQuote(
            quote = "在攝政王的注視下，國會的權力鬥爭即將展開",
            attribution = "Under the Prince Regent's gaze..."
        )
    }
}
