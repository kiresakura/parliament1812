package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
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
import com.parliament1812.R
import com.parliament1812.ui.components.*
import com.parliament1812.ui.theme.*
import kotlinx.coroutines.delay

// Bill data class
data class Bill(
    val id: String,
    val number: String,
    val title: String,
    val description: String,
    val quote: String,
    val impacts: List<BillImpact>,
    val isApproved: Boolean? = null
)

data class BillImpact(
    val name: String,
    val value: String,
    val isPositive: Boolean
)

data class RelatedBill(
    val id: String,
    val title: String,
    val subtitle: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DebateScreen(
    roomCode: String,
    playerId: String,
    onNavigateBack: () -> Unit,
    onVote: (Boolean) -> Unit, // true = approve, false = oppose
    onMenuClick: () -> Unit
) {
    // Sample bill data - in real app, this comes from ViewModel
    val currentBill = remember {
        Bill(
            id = "1812-04",
            number = "#1812-04",
            title = "反動亂法",
            description = "於近期北部工業區的動盪局勢，本院提議暫時中止人身保護令，並授權地方治安官在必要時動用民兵鎮壓非法集會。",
            quote = "「為了維護帝國的秩序與商業的繁榮，必要的手段是不可避免的犧牲。」",
            impacts = listOf(
                BillImpact("公眾秩序", "+20", true),
                BillImpact("工業產出", "+10%", true),
                BillImpact("自由黨派支持度", "-15", false)
            ),
            isApproved = true
        )
    }

    val relatedBills = remember {
        listOf(
            RelatedBill("1", "動物法修正案", "關於工作馬匹入門，需出示健康證書等規定。"),
            RelatedBill("2", "皇家海軍撥款", "政府額外撥款，消除所有船艦的安全疑慮。"),
            RelatedBill("3", "緊急通道重劃", "重新分配地方選舉。")
        )
    }

    // Timer state
    var remainingSeconds by remember { mutableStateOf(45L) }
    LaunchedEffect(Unit) {
        while (remainingSeconds > 0) {
            delay(1000)
            remainingSeconds--
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

        // Dark Overlay - darker green tint like Figma
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color(0xFF1A2E1A).copy(alpha = 0.95f),
                            Color(0xFF0D1A0D).copy(alpha = 0.98f)
                        )
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
        ) {
            // Header
            DebateHeader(
                roomCode = roomCode,
                phaseName = "表決階段",
                onTimerClick = {},
                onMenuClick = onMenuClick
            )

            // Scrollable Content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Main Bill Card
                BillCard(bill = currentBill)

                Spacer(modifier = Modifier.height(16.dp))

                // Related Bills Row
                RelatedBillsRow(bills = relatedBills)

                Spacer(modifier = Modifier.height(100.dp)) // Space for bottom bar
            }

            // Bottom Voting Bar
            VotingBottomBar(
                remainingSeconds = remainingSeconds,
                onOppose = { onVote(false) },
                onApprove = { onVote(true) }
            )
        }
    }
}

@Composable
private fun DebateHeader(
    roomCode: String,
    phaseName: String,
    onTimerClick: () -> Unit,
    onMenuClick: () -> Unit
) {
    Surface(
        color = Color(0xFF1A2E1A).copy(alpha = 0.95f),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Year and Session info
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "YEAR 1812",
                        color = Gold.copy(alpha = 0.7f),
                        fontSize = 10.sp,
                        letterSpacing = 2.sp
                    )
                    Text(
                        text = "秋季會期",
                        color = TextPrimary,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        fontFamily = FontFamily.Serif
                    )
                }

                // Phase Tab
                PhaseTab(
                    phaseName = phaseName,
                    isActive = true
                )

                Spacer(modifier = Modifier.width(12.dp))

                // Timer Icon
                IconButton(
                    onClick = onTimerClick,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Timer,
                        contentDescription = "計時器",
                        tint = Gold.copy(alpha = 0.7f),
                        modifier = Modifier.size(22.dp)
                    )
                }

                // Menu Icon
                IconButton(
                    onClick = onMenuClick,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Menu,
                        contentDescription = "選單",
                        tint = Gold.copy(alpha = 0.7f),
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            // Gold divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Gold.copy(alpha = 0.5f),
                                Gold.copy(alpha = 0.5f),
                                Color.Transparent
                            )
                        )
                    )
            )
        }
    }
}

@Composable
private fun PhaseTab(
    phaseName: String,
    isActive: Boolean
) {
    val backgroundColor = if (isActive) Gold.copy(alpha = 0.15f) else Color.Transparent
    val borderColor = if (isActive) Gold.copy(alpha = 0.5f) else Gold.copy(alpha = 0.2f)

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(backgroundColor)
            .border(1.dp, borderColor, RoundedCornerShape(20.dp))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = "⚖", fontSize = 14.sp)
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = phaseName,
            color = if (isActive) Gold else TextMuted,
            fontSize = 13.sp,
            fontWeight = if (isActive) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}

@Composable
private fun BillCard(bill: Bill) {
    val cardShape = RoundedCornerShape(16.dp)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    colors = listOf(
                        Gold.copy(alpha = 0.4f),
                        Gold.copy(alpha = 0.2f),
                        Gold.copy(alpha = 0.4f)
                    )
                ),
                shape = cardShape
            ),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1E3320).copy(alpha = 0.9f)
        ),
        shape = cardShape
    ) {
        Box {
            Column(
                modifier = Modifier.padding(20.dp)
            ) {
                // Bill Number Badge
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = "議案 ${bill.number}",
                        color = Gold.copy(alpha = 0.8f),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 1.sp
                    )

                    // Decorative icon (scales of justice)
                    Text(text = "⚖", fontSize = 24.sp, color = Gold.copy(alpha = 0.3f))
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Bill Title
                Text(
                    text = bill.title,
                    color = TextPrimary,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Description with icon
                Row(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "📜",
                        fontSize = 20.sp,
                        modifier = Modifier.padding(top = 2.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = bill.description,
                        color = TextSecondary,
                        fontSize = 14.sp,
                        lineHeight = 22.sp
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Quote
                Text(
                    text = bill.quote,
                    color = Gold.copy(alpha = 0.7f),
                    fontSize = 13.sp,
                    fontStyle = FontStyle.Italic,
                    lineHeight = 20.sp,
                    modifier = Modifier.padding(start = 16.dp)
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Divider
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Gold.copy(alpha = 0.2f))
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Expected Impact Section
                Text(
                    text = "預期影響",
                    color = TextMuted,
                    fontSize = 12.sp,
                    letterSpacing = 1.sp
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Impact items
                bill.impacts.forEach { impact ->
                    ImpactItem(impact = impact)
                    Spacer(modifier = Modifier.height(6.dp))
                }
            }

            // Approval Stamp (if approved)
            if (bill.isApproved == true) {
                ApprovalStamp(
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = 24.dp)
                        .offset(y = 40.dp)
                )
            }
        }
    }
}

@Composable
private fun ImpactItem(impact: BillImpact) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Arrow indicator
        val arrowColor = if (impact.isPositive) Success else Error
        Text(
            text = if (impact.isPositive) "▲" else "▼",
            color = arrowColor,
            fontSize = 10.sp
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = impact.name,
            color = TextSecondary,
            fontSize = 13.sp
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = impact.value,
            color = if (impact.isPositive) Success else Error,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun ApprovalStamp(modifier: Modifier = Modifier) {
    // Animated rotation for stamp effect
    val infiniteTransition = rememberInfiniteTransition(label = "stampPulse")
    val rotation by infiniteTransition.animateFloat(
        initialValue = -12f,
        targetValue = -8f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "rotation"
    )

    Box(
        modifier = modifier
            .size(90.dp)
            .rotate(rotation)
            .border(
                width = 3.dp,
                color = Success,
                shape = CircleShape
            )
            .padding(8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "通過",
                color = Success,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif
            )
            Text(
                text = "APPROVED",
                color = Success,
                fontSize = 8.sp,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
private fun RelatedBillsRow(bills: List<RelatedBill>) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 4.dp)
    ) {
        items(bills) { bill ->
            RelatedBillCard(bill = bill)
        }
    }
}

@Composable
private fun RelatedBillCard(bill: RelatedBill) {
    val cardShape = RoundedCornerShape(12.dp)

    Card(
        modifier = Modifier
            .width(140.dp)
            .border(1.dp, Gold.copy(alpha = 0.3f), cardShape),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1E3320).copy(alpha = 0.8f)
        ),
        shape = cardShape
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = bill.title,
                color = Gold,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = bill.subtitle,
                color = TextMuted,
                fontSize = 10.sp,
                lineHeight = 14.sp,
                maxLines = 3
            )
        }
    }
}

@Composable
private fun VotingBottomBar(
    remainingSeconds: Long,
    onOppose: () -> Unit,
    onApprove: () -> Unit
) {
    Surface(
        color = Color(0xFF1A2E1A),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column {
            // Top divider
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Gold.copy(alpha = 0.3f))
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Oppose Button
                OpponentButton(
                    onClick = onOppose
                )

                // Timer Display
                TimerBadge(remainingSeconds = remainingSeconds)

                // Approve Button
                ApproveButton(
                    onClick = onApprove
                )
            }
        }
    }
}

@Composable
private fun OpponentButton(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(24.dp))
            .background(Color(0xFF2A3A2A))
            .border(1.dp, Gold.copy(alpha = 0.3f), RoundedCornerShape(24.dp))
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "反對",
            color = TextSecondary,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(text = "👎", fontSize = 16.sp)
    }
}

@Composable
private fun ApproveButton(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(24.dp))
            .background(
                Brush.horizontalGradient(
                    colors = listOf(Gold, GoldAccent)
                )
            )
            .clickable { onClick() }
            .padding(horizontal = 20.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "贊成",
            color = DarkBackground,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(text = "👍", fontSize = 16.sp)
    }
}

@Composable
private fun TimerBadge(remainingSeconds: Long) {
    val minutes = remainingSeconds / 60
    val seconds = remainingSeconds % 60
    val isUrgent = remainingSeconds < 30

    // Pulsing animation for urgent timer
    val infiniteTransition = rememberInfiniteTransition(label = "timerPulse")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = if (isUrgent) 0.6f else 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "TIME",
            color = Gold.copy(alpha = 0.6f),
            fontSize = 10.sp,
            letterSpacing = 2.sp
        )

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(
                    if (isUrgent) Error.copy(alpha = 0.2f * alpha)
                    else Color(0xFF2A3A2A)
                )
                .border(
                    1.dp,
                    if (isUrgent) Error.copy(alpha = alpha) else Gold.copy(alpha = 0.3f),
                    RoundedCornerShape(8.dp)
                )
                .padding(horizontal = 16.dp, vertical = 6.dp)
        ) {
            Text(
                text = String.format("%02d:%02d", minutes, seconds),
                color = if (isUrgent) Error.copy(alpha = alpha) else Gold,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace
            )
        }
    }
}
