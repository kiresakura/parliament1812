package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.parliament1812.R
import com.parliament1812.data.remote.PlayerBrief
import com.parliament1812.ui.theme.*
import com.parliament1812.viewmodels.ChatMessage
import com.parliament1812.viewmodels.ConversationPreview
import com.parliament1812.viewmodels.MessageViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MessageScreen(
    roomCode: String,
    playerId: String,
    onNavigateBack: () -> Unit,
    viewModel: MessageViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()

    // Initialize
    LaunchedEffect(roomCode, playerId) {
        viewModel.initialize(roomCode, playerId)
    }

    // Scroll to bottom when new message added
    LaunchedEffect(uiState.messages.size) {
        if (uiState.messages.isNotEmpty()) {
            coroutineScope.launch {
                listState.animateScrollToItem(uiState.messages.size - 1)
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

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Header
            MessageHeader(
                isInChat = uiState.currentChatPlayerId != null,
                chatNickname = uiState.currentChatNickname,
                totalUnread = uiState.totalUnread,
                onNavigateBack = {
                    if (uiState.currentChatPlayerId != null) {
                        viewModel.closeChat()
                    } else {
                        onNavigateBack()
                    }
                }
            )

            // Content
            if (uiState.currentChatPlayerId != null) {
                // Chat View
                ChatView(
                    messages = uiState.messages,
                    messageInput = uiState.messageInput,
                    isSending = uiState.isSending,
                    isLoading = uiState.isLoading,
                    listState = listState,
                    onInputChange = { viewModel.updateMessageInput(it) },
                    onSend = { viewModel.sendMessage() }
                )
            } else {
                // Conversations List
                ConversationsView(
                    conversations = uiState.conversations,
                    availablePlayers = uiState.availablePlayers,
                    isLoading = uiState.isLoading,
                    onSelectPlayer = { playerId, nickname ->
                        viewModel.openChat(playerId, nickname)
                    }
                )
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
private fun MessageHeader(
    isInChat: Boolean,
    chatNickname: String,
    totalUnread: Int,
    onNavigateBack: () -> Unit
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
                        text = if (isInChat) chatNickname else "私訊",
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = if (isInChat) "PRIVATE CONVERSATION" else "PRIVATE MESSAGES",
                        color = TextMuted,
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                }

                if (!isInChat && totalUnread > 0) {
                    Badge(
                        containerColor = Error,
                        contentColor = TextPrimary
                    ) {
                        Text("$totalUnread")
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                Icon(
                    imageVector = if (isInChat) Icons.Default.ChatBubble else Icons.Default.Mail,
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
private fun ConversationsView(
    conversations: List<ConversationPreview>,
    availablePlayers: List<PlayerBrief>,
    isLoading: Boolean,
    onSelectPlayer: (String, String) -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item { Spacer(modifier = Modifier.height(8.dp)) }

        // Info Card
        item {
            Card(
                colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
                shape = RoundedCornerShape(8.dp)
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = Gold,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "私下密謀是遊戲的核心策略！選擇一位玩家開始對話。",
                        color = TextSecondary,
                        fontSize = 13.sp,
                        lineHeight = 18.sp
                    )
                }
            }
        }

        // Loading indicator
        if (isLoading) {
            item {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = Gold)
                }
            }
        }

        // Existing conversations
        if (conversations.isNotEmpty()) {
            item {
                Text(
                    text = "對話記錄",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }

            items(conversations) { conversation ->
                ConversationCard(
                    conversation = conversation,
                    onClick = { onSelectPlayer(conversation.playerId, conversation.nickname) }
                )
            }
        }

        // Available players for new conversations
        val playersNotInConversation = availablePlayers.filter { player ->
            conversations.none { it.playerId == player.id }
        }

        if (playersNotInConversation.isNotEmpty()) {
            item {
                Text(
                    text = "開始新對話",
                    color = Gold,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            }

            items(playersNotInConversation) { player ->
                NewConversationCard(
                    player = player,
                    onClick = { onSelectPlayer(player.id, player.nickname) }
                )
            }
        }

        item { Spacer(modifier = Modifier.height(24.dp)) }
    }
}

@Composable
private fun ConversationCard(
    conversation: ConversationPreview,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent),
        shape = RoundedCornerShape(8.dp)
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
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(DarkSurfaceVariant)
                    .border(1.dp, GoldMuted, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = conversation.nickname.firstOrNull()?.uppercase() ?: "?",
                    color = Gold,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = conversation.nickname,
                        color = TextPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    if (conversation.unreadCount > 0) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Badge(
                            containerColor = Error,
                            contentColor = TextPrimary
                        ) {
                            Text("${conversation.unreadCount}")
                        }
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = conversation.lastMessage,
                    color = TextSecondary,
                    fontSize = 13.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = TextMuted
            )
        }
    }
}

@Composable
private fun NewConversationCard(
    player: PlayerBrief,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = CardBackgroundTranslucent.copy(alpha = 0.5f)),
        shape = RoundedCornerShape(8.dp)
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
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(DarkSurfaceVariant)
                    .border(1.dp, CardBorder, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = player.nickname.firstOrNull()?.uppercase() ?: "?",
                    color = TextMuted,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = player.nickname,
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "開始對話",
                    color = TextMuted,
                    fontSize = 12.sp
                )
            }

            Icon(
                imageVector = Icons.Default.Add,
                contentDescription = null,
                tint = Gold
            )
        }
    }
}

@Composable
private fun ChatView(
    messages: List<ChatMessage>,
    messageInput: String,
    isSending: Boolean,
    isLoading: Boolean,
    listState: androidx.compose.foundation.lazy.LazyListState,
    onInputChange: (String) -> Unit,
    onSend: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        // Messages
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp),
            state = listState,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item { Spacer(modifier = Modifier.height(8.dp)) }

            if (isLoading && messages.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Gold)
                    }
                }
            }

            if (messages.isEmpty() && !isLoading) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "尚無訊息，開始對話吧！",
                            color = TextMuted,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }

            items(messages) { message ->
                MessageBubble(message = message)
            }

            item { Spacer(modifier = Modifier.height(8.dp)) }
        }

        // Input Area
        MessageInputBar(
            input = messageInput,
            isSending = isSending,
            onInputChange = onInputChange,
            onSend = onSend
        )
    }
}

@Composable
private fun MessageBubble(message: ChatMessage) {
    val alignment = if (message.isFromMe) Alignment.End else Alignment.Start
    val backgroundColor = if (message.isFromMe) Gold.copy(alpha = 0.2f) else CardBackgroundTranslucent
    val borderColor = if (message.isFromMe) Gold else CardBorder

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = alignment
    ) {
        Card(
            modifier = Modifier.widthIn(max = 280.dp),
            colors = CardDefaults.cardColors(containerColor = backgroundColor),
            shape = RoundedCornerShape(
                topStart = 12.dp,
                topEnd = 12.dp,
                bottomStart = if (message.isFromMe) 12.dp else 4.dp,
                bottomEnd = if (message.isFromMe) 4.dp else 12.dp
            ),
            border = CardDefaults.outlinedCardBorder().copy(
                brush = Brush.horizontalGradient(listOf(borderColor, borderColor))
            )
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = message.content,
                    color = TextPrimary,
                    fontSize = 14.sp,
                    lineHeight = 20.sp
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = formatTime(message.sentAt),
                    color = TextMuted,
                    fontSize = 10.sp,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}

@Composable
private fun MessageInputBar(
    input: String,
    isSending: Boolean,
    onInputChange: (String) -> Unit,
    onSend: () -> Unit
) {
    Surface(
        color = DarkOverlay95,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            HorizontalDivider(color = DividerGold, thickness = 1.dp)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = input,
                    onValueChange = onInputChange,
                    modifier = Modifier.weight(1f),
                    placeholder = {
                        Text(
                            text = "輸入訊息...",
                            color = TextMuted
                        )
                    },
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = TextPrimary,
                        unfocusedTextColor = TextPrimary,
                        cursorColor = Gold,
                        focusedBorderColor = Gold,
                        unfocusedBorderColor = CardBorder,
                        focusedContainerColor = DarkSurfaceVariant,
                        unfocusedContainerColor = DarkSurfaceVariant
                    ),
                    shape = RoundedCornerShape(24.dp),
                    maxLines = 3
                )

                Spacer(modifier = Modifier.width(12.dp))

                IconButton(
                    onClick = onSend,
                    enabled = input.isNotBlank() && !isSending,
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(if (input.isNotBlank()) Gold else GoldMuted.copy(alpha = 0.3f))
                ) {
                    if (isSending) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = DarkBackground,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Send,
                            contentDescription = "發送",
                            tint = if (input.isNotBlank()) DarkBackground else TextMuted
                        )
                    }
                }
            }
        }
    }
}

private fun formatTime(isoString: String): String {
    return try {
        val instant = java.time.Instant.parse(isoString)
        val zoned = instant.atZone(java.time.ZoneId.systemDefault())
        val formatter = java.time.format.DateTimeFormatter.ofPattern("HH:mm")
        zoned.format(formatter)
    } catch (e: Exception) {
        ""
    }
}
