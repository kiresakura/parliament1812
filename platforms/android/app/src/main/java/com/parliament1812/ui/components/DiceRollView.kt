package com.parliament1812.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.parliament1812.ui.theme.*
import kotlinx.coroutines.delay
import kotlin.random.Random

/**
 * Animated dice roll view for international events (Phase 7)
 * Shows rolling animation then reveals the result with triggered/not triggered state
 */
@Composable
fun DiceRollView(
    value: Int,
    threshold: Int,
    triggered: Boolean,
    isVisible: Boolean,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    if (!isVisible) return

    var isRolling by remember { mutableStateOf(true) }
    var displayValue by remember { mutableIntStateOf(1) }
    var showResult by remember { mutableStateOf(false) }

    // Rolling animation - cycle through random values
    LaunchedEffect(Unit) {
        // Roll for 1.5 seconds
        repeat(15) {
            displayValue = Random.nextInt(1, 7)
            delay(100)
        }
        // Show final value
        displayValue = value
        isRolling = false
        delay(300)
        showResult = true
    }

    // Auto-dismiss after showing result
    LaunchedEffect(showResult) {
        if (showResult) {
            delay(3000)
            onDismiss()
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.85f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Title
            Text(
                text = "國際情勢骰",
                color = Gold,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 4.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "INTERNATIONAL EVENTS",
                color = TextMuted,
                fontSize = 12.sp,
                letterSpacing = 2.sp
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Dice
            AnimatedDice(
                value = displayValue,
                isRolling = isRolling,
                triggered = triggered,
                showResult = showResult
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Threshold info
            Text(
                text = "觸發門檻: ≥$threshold",
                color = TextSecondary,
                fontSize = 14.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Result message
            if (showResult) {
                ResultMessage(
                    value = value,
                    threshold = threshold,
                    triggered = triggered
                )
            }
        }
    }
}

/**
 * Animated dice with rolling effect
 */
@Composable
private fun AnimatedDice(
    value: Int,
    isRolling: Boolean,
    triggered: Boolean,
    showResult: Boolean,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "diceRoll")

    // Rotation animation during rolling
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(300, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    // Scale bounce when stopped
    val scale by animateFloatAsState(
        targetValue = if (isRolling) 1f else 1.2f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "scale"
    )

    // Glow effect when triggered
    val glowAlpha by animateFloatAsState(
        targetValue = if (showResult && triggered) 0.8f else 0f,
        animationSpec = tween(500),
        label = "glow"
    )

    Box(
        modifier = modifier
            .size(120.dp)
            .scale(scale)
            .rotate(if (isRolling) rotation else 0f),
        contentAlignment = Alignment.Center
    ) {
        // Glow background when triggered
        if (glowAlpha > 0) {
            Canvas(modifier = Modifier.size(140.dp)) {
                drawCircle(
                    color = Success.copy(alpha = glowAlpha * 0.5f),
                    radius = size.minDimension / 2
                )
            }
        }

        // Dice body
        Canvas(modifier = Modifier.size(100.dp)) {
            val borderColor = when {
                showResult && triggered -> Success
                showResult && !triggered -> Error
                else -> Gold
            }

            // Dice background
            drawRoundRect(
                color = DarkBackground,
                cornerRadius = CornerRadius(16.dp.toPx()),
                size = size
            )

            // Dice border
            drawRoundRect(
                color = borderColor,
                cornerRadius = CornerRadius(16.dp.toPx()),
                size = size,
                style = Stroke(width = 3.dp.toPx())
            )

            // Draw pips based on value
            drawDicePips(value, size, Gold)
        }
    }
}

/**
 * Draw dice pips (dots) for a given value
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawDicePips(
    value: Int,
    diceSize: Size,
    color: Color
) {
    val pipRadius = diceSize.width * 0.08f
    val centerX = diceSize.width / 2
    val centerY = diceSize.height / 2
    val offset = diceSize.width * 0.25f

    // Pip positions based on dice value
    val positions = when (value) {
        1 -> listOf(Offset(centerX, centerY))
        2 -> listOf(
            Offset(centerX - offset, centerY - offset),
            Offset(centerX + offset, centerY + offset)
        )
        3 -> listOf(
            Offset(centerX - offset, centerY - offset),
            Offset(centerX, centerY),
            Offset(centerX + offset, centerY + offset)
        )
        4 -> listOf(
            Offset(centerX - offset, centerY - offset),
            Offset(centerX + offset, centerY - offset),
            Offset(centerX - offset, centerY + offset),
            Offset(centerX + offset, centerY + offset)
        )
        5 -> listOf(
            Offset(centerX - offset, centerY - offset),
            Offset(centerX + offset, centerY - offset),
            Offset(centerX, centerY),
            Offset(centerX - offset, centerY + offset),
            Offset(centerX + offset, centerY + offset)
        )
        6 -> listOf(
            Offset(centerX - offset, centerY - offset),
            Offset(centerX + offset, centerY - offset),
            Offset(centerX - offset, centerY),
            Offset(centerX + offset, centerY),
            Offset(centerX - offset, centerY + offset),
            Offset(centerX + offset, centerY + offset)
        )
        else -> emptyList()
    }

    positions.forEach { pos ->
        drawCircle(
            color = color,
            radius = pipRadius,
            center = pos
        )
    }
}

/**
 * Result message display
 */
@Composable
private fun ResultMessage(
    value: Int,
    threshold: Int,
    triggered: Boolean,
    modifier: Modifier = Modifier
) {
    val resultColor = if (triggered) Success else Error
    val resultText = if (triggered) "事件觸發！" else "未觸發"
    val resultEmoji = if (triggered) "⚡" else "✓"

    Column(
        modifier = modifier
            .background(
                resultColor.copy(alpha = 0.2f),
                RoundedCornerShape(12.dp)
            )
            .border(
                1.dp,
                resultColor.copy(alpha = 0.5f),
                RoundedCornerShape(12.dp)
            )
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = resultEmoji,
            fontSize = 28.sp
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = resultText,
            color = resultColor,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "擲出 $value（需要 ≥$threshold）",
            color = TextSecondary,
            fontSize = 14.sp
        )
    }
}

/**
 * Compact dice result badge for inline display
 */
@Composable
fun DiceResultBadge(
    value: Int,
    threshold: Int,
    triggered: Boolean,
    modifier: Modifier = Modifier
) {
    val color = if (triggered) Success else Warning

    Row(
        modifier = modifier
            .background(color.copy(alpha = 0.2f), RoundedCornerShape(8.dp))
            .border(1.dp, color.copy(alpha = 0.5f), RoundedCornerShape(8.dp))
            .padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "🎲",
            fontSize = 16.sp
        )
        Text(
            text = "$value",
            color = color,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = if (triggered) "觸發" else "未觸發",
            color = TextSecondary,
            fontSize = 12.sp
        )
    }
}
