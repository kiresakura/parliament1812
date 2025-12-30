package com.parliament1812.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.parliament1812.data.models.*
import com.parliament1812.ui.components.*
import com.parliament1812.ui.theme.*
import kotlinx.coroutines.delay
import kotlin.math.cos
import kotlin.math.sin

// ============================================
// 1812 國會風雲 - Event Screen Components
// Victorian Newspaper Style UI
// ============================================

/**
 * 突發事件主畫面
 * Displays the event with reveal animation and interactive choices
 */
@Composable
fun EventScreen(
    event: GameEventData,
    onEventComplete: (EventChoice?) -> Unit,
    modifier: Modifier = Modifier
) {
    var isRevealed by remember { mutableStateOf(false) }
    var selectedChoice by remember { mutableStateOf<EventChoice?>(null) }
    var showChoices by remember { mutableStateOf(false) }

    // Auto-reveal after a delay
    LaunchedEffect(Unit) {
        delay(500)
        isRevealed = true
        delay(1500)
        showChoices = true
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        // Hexagonal background pattern
        HexagonalPattern(
            modifier = Modifier.fillMaxSize(),
            hexSize = 40f,
            color = Gold.copy(alpha = 0.03f)
        )

        // Vignette overlay
        VignetteOverlay(
            modifier = Modifier.fillMaxSize(),
            intensity = 0.6f
        )

        // Main content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Header with animation
            EventHeader(
                isRevealed = isRevealed,
                category = event.category
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Event card with reveal animation
            EventRevealAnimation(isRevealed = isRevealed) {
                EventCardFull(
                    event = event,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            // Choices section (if available)
            if (event.hasChoices && showChoices) {
                Spacer(modifier = Modifier.height(32.dp))

                AnimatedVisibility(
                    visible = showChoices,
                    enter = fadeIn() + slideInVertically { it / 2 }
                ) {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Section title
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "◇",
                                color = Gold,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "國會必須做出決定",
                                color = TextSecondary,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                                letterSpacing = 2.sp
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "◇",
                                color = Gold,
                                fontSize = 14.sp
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Choice cards
                        event.choices?.forEachIndexed { index, choice ->
                            EventChoiceCard(
                                choice = choice,
                                index = index,
                                isSelected = selectedChoice?.id == choice.id,
                                onSelect = { selectedChoice = choice },
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Confirm button
                        AnimatedVisibility(
                            visible = selectedChoice != null,
                            enter = fadeIn() + scaleIn()
                        ) {
                            RegencyStyledButton(
                                text = "確認決定",
                                onClick = { onEventComplete(selectedChoice) },
                                icon = "⚔",
                                modifier = Modifier.fillMaxWidth(0.8f)
                            )
                        }
                    }
                }
            } else if (!event.hasChoices && showChoices) {
                // No choices - just show continue button
                Spacer(modifier = Modifier.height(32.dp))

                AnimatedVisibility(
                    visible = showChoices,
                    enter = fadeIn() + scaleIn()
                ) {
                    RegencyStyledButton(
                        text = "繼續",
                        onClick = { onEventComplete(null) },
                        icon = "→",
                        modifier = Modifier.fillMaxWidth(0.6f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

/**
 * 事件標題區域
 */
@Composable
private fun EventHeader(
    isRevealed: Boolean,
    category: EventCategory
) {
    val alpha by animateFloatAsState(
        targetValue = if (isRevealed) 1f else 0f,
        animationSpec = tween(800),
        label = "headerAlpha"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.alpha(alpha)
    ) {
        // Breaking news banner
        Box(
            modifier = Modifier
                .background(
                    brush = Brush.horizontalGradient(
                        colors = listOf(
                            VictorianRed.copy(alpha = 0f),
                            VictorianRed.copy(alpha = 0.8f),
                            VictorianRed.copy(alpha = 0f)
                        )
                    ),
                    shape = RoundedCornerShape(4.dp)
                )
                .padding(horizontal = 24.dp, vertical = 6.dp)
        ) {
            Text(
                text = "⚡ 緊急快報 ⚡",
                color = TextPrimary,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 4.sp
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Category indicator
        Text(
            text = if (category == EventCategory.DOMESTIC) "國內消息" else "國際情報",
            color = Gold.copy(alpha = 0.7f),
            fontSize = 11.sp,
            letterSpacing = 3.sp
        )
    }
}

/**
 * 事件揭示動畫容器
 */
@Composable
fun EventRevealAnimation(
    isRevealed: Boolean,
    content: @Composable () -> Unit
) {
    val scale by animateFloatAsState(
        targetValue = if (isRevealed) 1f else 0.8f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "revealScale"
    )

    val alpha by animateFloatAsState(
        targetValue = if (isRevealed) 1f else 0f,
        animationSpec = tween(600),
        label = "revealAlpha"
    )

    val rotation by animateFloatAsState(
        targetValue = if (isRevealed) 0f else -5f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy
        ),
        label = "revealRotation"
    )

    Box(
        modifier = Modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
                rotationZ = rotation
                this.alpha = alpha
            }
    ) {
        content()
    }
}

/**
 * 完整事件卡片 - Victorian報紙風格
 */
@Composable
fun EventCardFull(
    event: GameEventData,
    modifier: Modifier = Modifier
) {
    val cardShape = CutCornerShape(topStart = 16.dp, bottomEnd = 16.dp)

    // Pulsing glow animation for urgency
    val infiniteTransition = rememberInfiniteTransition(label = "eventGlow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowPulse"
    )

    Box(
        modifier = modifier
            .shadow(
                elevation = 16.dp,
                shape = cardShape,
                ambientColor = event.type.color.copy(alpha = glowAlpha),
                spotColor = event.type.color.copy(alpha = glowAlpha * 0.5f)
            )
    ) {
        Card(
            modifier = Modifier
                .border(
                    width = 2.dp,
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Gold.copy(alpha = 0.6f),
                            event.type.color.copy(alpha = 0.4f),
                            Gold.copy(alpha = 0.6f)
                        )
                    ),
                    shape = cardShape
                ),
            colors = CardDefaults.cardColors(
                containerColor = CardBackground
            ),
            shape = cardShape
        ) {
            Column(
                modifier = Modifier.padding(24.dp)
            ) {
                // Newspaper header
                NewspaperHeader(event = event)

                Spacer(modifier = Modifier.height(16.dp))

                // Decorative divider
                GoldDivider(withDiamond = true)

                Spacer(modifier = Modifier.height(16.dp))

                // Event title
                Text(
                    text = event.title,
                    color = TextPrimary,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                // English subtitle
                Text(
                    text = event.englishTitle,
                    color = TextMuted,
                    fontSize = 12.sp,
                    fontStyle = FontStyle.Italic,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Description in newspaper style
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            DarkBackground.copy(alpha = 0.5f),
                            RoundedCornerShape(8.dp)
                        )
                        .border(
                            1.dp,
                            Gold.copy(alpha = 0.1f),
                            RoundedCornerShape(8.dp)
                        )
                        .padding(16.dp)
                ) {
                    // Drop cap style first letter
                    Row {
                        Text(
                            text = event.description.first().toString(),
                            color = Gold,
                            fontSize = 36.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = FontFamily.Serif,
                            modifier = Modifier.padding(end = 4.dp)
                        )
                        Text(
                            text = event.description.drop(1),
                            color = TextSecondary,
                            fontSize = 14.sp,
                            lineHeight = 22.sp,
                            fontFamily = FontFamily.Serif
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Severity indicator
                SeverityIndicator(
                    severity = event.severity,
                    severityText = event.getSeverityText()
                )

                // Effects section
                if (event.effects.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "影響效果",
                        color = TextMuted,
                        fontSize = 11.sp,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )

                    event.effects.forEach { effect ->
                        EventEffectItem(
                            effect = effect,
                            modifier = Modifier.padding(vertical = 4.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Bottom decorative divider
                GoldDivider(withDiamond = false)
            }
        }
    }
}

/**
 * 報紙風格標題區
 */
@Composable
private fun NewspaperHeader(
    event: GameEventData
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Newspaper name
        Text(
            text = "THE PARLIAMENTARY GAZETTE",
            color = Gold,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 4.sp
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Type and category badges
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Category badge
            EventTypeBadge(
                text = event.category.displayName,
                color = if (event.category == EventCategory.DOMESTIC) VictorianBlue else VictorianGreen
            )

            Spacer(modifier = Modifier.width(8.dp))

            Text(
                text = "•",
                color = TextMuted,
                fontSize = 10.sp
            )

            Spacer(modifier = Modifier.width(8.dp))

            // Type badge
            EventTypeBadge(
                text = event.type.displayName,
                color = event.type.color
            )
        }
    }
}

/**
 * 事件類型標籤
 */
@Composable
private fun EventTypeBadge(
    text: String,
    color: Color
) {
    Box(
        modifier = Modifier
            .background(
                color = color.copy(alpha = 0.2f),
                shape = RoundedCornerShape(4.dp)
            )
            .border(
                1.dp,
                color.copy(alpha = 0.4f),
                RoundedCornerShape(4.dp)
            )
            .padding(horizontal = 8.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            color = color,
            fontSize = 10.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * 嚴重程度指示器
 */
@Composable
private fun SeverityIndicator(
    severity: Int,
    severityText: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "嚴重程度：",
            color = TextMuted,
            fontSize = 11.sp
        )

        Spacer(modifier = Modifier.width(8.dp))

        // Severity dots
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(5) { index ->
                val isActive = index < severity
                val dotColor = when {
                    !isActive -> TextMuted.copy(alpha = 0.3f)
                    severity >= 4 -> Error
                    severity >= 3 -> Warning
                    else -> Success
                }

                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .background(dotColor, RoundedCornerShape(2.dp))
                )
            }
        }

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = severityText,
            color = when {
                severity >= 4 -> Error
                severity >= 3 -> Warning
                else -> TextMuted
            },
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * Row with spacing - compatibility helper
 */
@Composable
private fun Row(
    spacing: Int,
    content: @Composable RowScope.() -> Unit
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(spacing.dp),
        content = content
    )
}

/**
 * 事件效果項目
 */
@Composable
fun EventEffectItem(
    effect: EventEffect,
    modifier: Modifier = Modifier
) {
    val isPositive = effect.isPositive()
    val isNegative = effect.isNegative()

    val backgroundColor = when {
        isPositive -> Success.copy(alpha = 0.1f)
        isNegative -> Error.copy(alpha = 0.1f)
        else -> Gold.copy(alpha = 0.1f)
    }

    val borderColor = when {
        isPositive -> Success.copy(alpha = 0.3f)
        isNegative -> Error.copy(alpha = 0.3f)
        else -> Gold.copy(alpha = 0.3f)
    }

    val iconColor = when {
        isPositive -> Success
        isNegative -> Error
        else -> Gold
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(backgroundColor, RoundedCornerShape(6.dp))
            .border(1.dp, borderColor, RoundedCornerShape(6.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Effect icon
        Icon(
            imageVector = when {
                isPositive -> Icons.Default.TrendingUp
                isNegative -> Icons.Default.TrendingDown
                else -> Icons.Default.Remove
            },
            contentDescription = null,
            tint = iconColor,
            modifier = Modifier.size(16.dp)
        )

        Spacer(modifier = Modifier.width(8.dp))

        // Target role (if specified)
        effect.targetRole?.let { role ->
            FactionBadge(
                faction = role,
                modifier = Modifier.padding(end = 8.dp)
            )
        }

        // Effect description
        Text(
            text = effect.getDescription(),
            color = TextSecondary,
            fontSize = 12.sp,
            modifier = Modifier.weight(1f)
        )

        // Condition (if any)
        effect.condition?.let { condition ->
            Text(
                text = "($condition)",
                color = TextMuted,
                fontSize = 10.sp,
                fontStyle = FontStyle.Italic
            )
        }
    }
}

/**
 * 事件選項卡片
 */
@Composable
fun EventChoiceCard(
    choice: EventChoice,
    index: Int,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier
) {
    val letters = listOf("甲", "乙", "丙", "丁")
    val letter = letters.getOrElse(index) { "?" }

    val borderColor by animateColorAsState(
        targetValue = if (isSelected) Gold else CardBorder.copy(alpha = 0.5f),
        animationSpec = tween(300),
        label = "choiceBorder"
    )

    val backgroundColor by animateColorAsState(
        targetValue = if (isSelected) Gold.copy(alpha = 0.1f) else CardBackground,
        animationSpec = tween(300),
        label = "choiceBackground"
    )

    val scale by animateFloatAsState(
        targetValue = if (isSelected) 1.02f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
        label = "choiceScale"
    )

    Card(
        modifier = modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable { onSelect() },
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            // Letter indicator
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(
                        if (isSelected) Gold else Gold.copy(alpha = 0.2f),
                        RoundedCornerShape(8.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = letter,
                    color = if (isSelected) DarkBackground else Gold,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Choice content
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = choice.title,
                    color = if (isSelected) Gold else TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = choice.description,
                    color = TextSecondary,
                    fontSize = 13.sp,
                    lineHeight = 18.sp
                )

                // Effects preview
                if (choice.effects.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        choice.effects.take(2).forEach { effect ->
                            EffectPreviewChip(effect = effect)
                        }
                        if (choice.effects.size > 2) {
                            Text(
                                text = "+${choice.effects.size - 2}",
                                color = TextMuted,
                                fontSize = 10.sp
                            )
                        }
                    }
                }
            }

            // Selection indicator
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "已選擇",
                    tint = Gold,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

/**
 * 效果預覽小標籤
 */
@Composable
private fun EffectPreviewChip(
    effect: EventEffect
) {
    val isPositive = effect.isPositive()
    val chipColor = if (isPositive) Success else Error

    Row(
        modifier = Modifier
            .background(
                chipColor.copy(alpha = 0.15f),
                RoundedCornerShape(4.dp)
            )
            .padding(horizontal = 6.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (isPositive) Icons.Default.ArrowUpward else Icons.Default.ArrowDownward,
            contentDescription = null,
            tint = chipColor,
            modifier = Modifier.size(10.dp)
        )
        Spacer(modifier = Modifier.width(2.dp))
        Text(
            text = effect.targetRole?.let { getRoleShortName(it) } ?: "",
            color = chipColor,
            fontSize = 9.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * Get short role name for chips
 */
private fun getRoleShortName(roleType: String): String {
    return when (roleType.lowercase()) {
        "worker" -> "工人"
        "factory_owner", "factory" -> "工廠主"
        "luddite" -> "盧德派"
        "reformer" -> "改革者"
        "mp" -> "議員"
        else -> roleType
    }
}

// ============================================
// Preview
// ============================================

@Preview(showBackground = true, backgroundColor = 0xFF1A1614)
@Composable
private fun EventScreenPreview() {
    Parliament1812Theme {
        EventScreen(
            event = EventRepository.ludditeRiot,
            onEventComplete = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF1A1614)
@Composable
private fun EventCardFullPreview() {
    Parliament1812Theme {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(DarkBackground)
                .padding(16.dp)
        ) {
            EventCardFull(
                event = EventRepository.factoryFire
            )
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF1A1614)
@Composable
private fun EventChoiceCardPreview() {
    Parliament1812Theme {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(DarkBackground)
                .padding(16.dp)
        ) {
            EventRepository.ludditeRiot.choices?.forEachIndexed { index, choice ->
                EventChoiceCard(
                    choice = choice,
                    index = index,
                    isSelected = index == 0,
                    onSelect = {}
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}
