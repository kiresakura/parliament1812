package com.parliament1812.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.parliament1812.ui.theme.*
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

// ============================================
// Victorian Era Decorative Components
// ============================================

/**
 * Animated gold shimmer effect for backgrounds
 */
@Composable
fun GoldShimmerEffect(
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val shimmerOffset by infiniteTransition.animateFloat(
        initialValue = -1f,
        targetValue = 2f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerOffset"
    )

    Canvas(modifier = modifier) {
        val shimmerBrush = Brush.linearGradient(
            colors = listOf(
                Color.Transparent,
                Gold.copy(alpha = 0.1f),
                Gold.copy(alpha = 0.2f),
                Gold.copy(alpha = 0.1f),
                Color.Transparent
            ),
            start = Offset(size.width * shimmerOffset, 0f),
            end = Offset(size.width * (shimmerOffset + 1f), size.height)
        )
        drawRect(brush = shimmerBrush)
    }
}

/**
 * Hexagonal background pattern (like Civilization 6)
 */
@Composable
fun HexagonalPattern(
    modifier: Modifier = Modifier,
    hexSize: Float = 60f,
    color: Color = Gold.copy(alpha = 0.05f)
) {
    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height
        val hexWidth = hexSize * 2
        val hexHeight = hexSize * 1.732f // sqrt(3)

        var row = 0
        var y = 0f
        while (y < height + hexHeight) {
            var x = if (row % 2 == 0) 0f else hexWidth * 0.75f
            while (x < width + hexWidth) {
                drawHexagon(
                    center = Offset(x, y),
                    size = hexSize,
                    color = color
                )
                x += hexWidth * 1.5f
            }
            y += hexHeight * 0.5f
            row++
        }
    }
}

private fun DrawScope.drawHexagon(
    center: Offset,
    size: Float,
    color: Color
) {
    val path = Path().apply {
        for (i in 0..5) {
            val angle = Math.PI / 3 * i - Math.PI / 6
            val x = center.x + size * cos(angle).toFloat()
            val y = center.y + size * sin(angle).toFloat()
            if (i == 0) moveTo(x, y) else lineTo(x, y)
        }
        close()
    }
    drawPath(path, color, style = Stroke(width = 1f))
}

/**
 * Victorian corner ornament
 */
@Composable
fun VictorianCornerOrnament(
    modifier: Modifier = Modifier,
    corner: Corner = Corner.TopLeft,
    color: Color = Gold.copy(alpha = 0.3f)
) {
    Canvas(modifier = modifier.size(80.dp)) {
        val ornamentColor = color
        val strokeWidth = 2f

        // Draw decorative swirls based on corner
        val path = Path().apply {
            when (corner) {
                Corner.TopLeft -> {
                    moveTo(0f, size.height * 0.8f)
                    cubicTo(
                        size.width * 0.1f, size.height * 0.5f,
                        size.width * 0.3f, size.height * 0.2f,
                        size.width * 0.8f, 0f
                    )
                    moveTo(0f, size.height * 0.6f)
                    cubicTo(
                        size.width * 0.1f, size.height * 0.3f,
                        size.width * 0.2f, size.height * 0.15f,
                        size.width * 0.6f, 0f
                    )
                    // Decorative curl
                    moveTo(size.width * 0.15f, size.height * 0.15f)
                    cubicTo(
                        size.width * 0.25f, size.height * 0.25f,
                        size.width * 0.2f, size.height * 0.35f,
                        size.width * 0.1f, size.height * 0.3f
                    )
                }
                Corner.TopRight -> {
                    moveTo(size.width, size.height * 0.8f)
                    cubicTo(
                        size.width * 0.9f, size.height * 0.5f,
                        size.width * 0.7f, size.height * 0.2f,
                        size.width * 0.2f, 0f
                    )
                    moveTo(size.width, size.height * 0.6f)
                    cubicTo(
                        size.width * 0.9f, size.height * 0.3f,
                        size.width * 0.8f, size.height * 0.15f,
                        size.width * 0.4f, 0f
                    )
                }
                Corner.BottomLeft -> {
                    moveTo(0f, size.height * 0.2f)
                    cubicTo(
                        size.width * 0.1f, size.height * 0.5f,
                        size.width * 0.3f, size.height * 0.8f,
                        size.width * 0.8f, size.height
                    )
                    moveTo(0f, size.height * 0.4f)
                    cubicTo(
                        size.width * 0.1f, size.height * 0.7f,
                        size.width * 0.2f, size.height * 0.85f,
                        size.width * 0.6f, size.height
                    )
                }
                Corner.BottomRight -> {
                    moveTo(size.width, size.height * 0.2f)
                    cubicTo(
                        size.width * 0.9f, size.height * 0.5f,
                        size.width * 0.7f, size.height * 0.8f,
                        size.width * 0.2f, size.height
                    )
                    moveTo(size.width, size.height * 0.4f)
                    cubicTo(
                        size.width * 0.9f, size.height * 0.7f,
                        size.width * 0.8f, size.height * 0.85f,
                        size.width * 0.4f, size.height
                    )
                }
            }
        }
        drawPath(path, ornamentColor, style = Stroke(width = strokeWidth))
    }
}

enum class Corner {
    TopLeft, TopRight, BottomLeft, BottomRight
}

/**
 * Decorative gold divider line with diamond centers
 */
@Composable
fun GoldDivider(
    modifier: Modifier = Modifier,
    withDiamond: Boolean = true
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(Color.Transparent, Gold.copy(alpha = 0.5f))
                    )
                )
        )
        if (withDiamond) {
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "◇",
                color = Gold,
                fontSize = 10.sp
            )
            Spacer(modifier = Modifier.width(8.dp))
        }
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(Gold.copy(alpha = 0.5f), Color.Transparent)
                    )
                )
        )
    }
}

/**
 * Animated floating particles (dust/candlelight effect)
 */
@Composable
fun AmbientParticles(
    modifier: Modifier = Modifier,
    particleCount: Int = 20
) {
    val particles = remember {
        List(particleCount) {
            Particle(
                x = Random.nextFloat(),
                y = Random.nextFloat(),
                size = Random.nextFloat() * 3f + 1f,
                speed = Random.nextFloat() * 0.5f + 0.2f,
                alpha = Random.nextFloat() * 0.3f + 0.1f
            )
        }
    }

    val infiniteTransition = rememberInfiniteTransition(label = "particles")
    val time by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(10000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "particleTime"
    )

    Canvas(modifier = modifier) {
        particles.forEach { particle ->
            val yOffset = (particle.y + time * particle.speed) % 1f
            val xWobble = sin(time * 6.28f + particle.x * 10f).toFloat() * 0.02f

            drawCircle(
                color = Gold.copy(alpha = particle.alpha * (1f - yOffset)),
                radius = particle.size,
                center = Offset(
                    x = (particle.x + xWobble) * size.width,
                    y = yOffset * size.height
                )
            )
        }
    }
}

private data class Particle(
    val x: Float,
    val y: Float,
    val size: Float,
    val speed: Float,
    val alpha: Float
)

/**
 * Wax seal animation component
 */
@Composable
fun WaxSeal(
    modifier: Modifier = Modifier,
    isRevealed: Boolean = false,
    onTap: () -> Unit = {},
    content: @Composable () -> Unit = {}
) {
    val scale by animateFloatAsState(
        targetValue = if (isRevealed) 0f else 1f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 300f),
        label = "sealScale"
    )

    val rotation by animateFloatAsState(
        targetValue = if (isRevealed) 360f else 0f,
        animationSpec = tween(500),
        label = "sealRotation"
    )

    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        // Content behind seal
        if (isRevealed) {
            content()
        }

        // Wax seal
        if (scale > 0.01f) {
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                        rotationZ = rotation
                    }
                    .shadow(8.dp, CircleShape)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                Color(0xFFB22222), // Firebrick
                                Color(0xFF8B0000)  // Dark Red
                            )
                        )
                    )
                    .border(2.dp, Gold.copy(alpha = 0.5f), CircleShape)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null
                    ) { onTap() },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "P",
                    color = Gold,
                    fontSize = 40.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Serif
                )
            }
        }
    }
}

/**
 * Victorian-style card with decorative border
 */
@Composable
fun VictorianCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    colors = listOf(
                        Gold.copy(alpha = 0.5f),
                        Gold.copy(alpha = 0.2f),
                        Gold.copy(alpha = 0.5f)
                    )
                ),
                shape = RoundedCornerShape(8.dp)
            ),
        colors = CardDefaults.cardColors(
            containerColor = CardBackgroundTranslucent
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

/**
 * Regency-era styled button with cut corner
 */
@Composable
fun RegencyStyledButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    isPrimary: Boolean = true,
    icon: String? = "☆"
) {
    val backgroundColor = when {
        !enabled -> Gold.copy(alpha = 0.3f)
        isPrimary -> Gold
        else -> Color.Transparent
    }

    val borderColor = if (enabled) Gold else Gold.copy(alpha = 0.3f)
    val textColor = when {
        !enabled -> DarkBackground.copy(alpha = 0.5f)
        isPrimary -> DarkBackground
        else -> Gold
    }

    Button(
        onClick = onClick,
        enabled = enabled && !isLoading,
        colors = ButtonDefaults.buttonColors(
            containerColor = backgroundColor,
            contentColor = textColor,
            disabledContainerColor = backgroundColor,
            disabledContentColor = textColor
        ),
        shape = CutCornerShape(bottomEnd = 12.dp),
        modifier = modifier
            .height(56.dp)
            .then(
                if (!isPrimary) Modifier.border(
                    1.dp,
                    borderColor,
                    CutCornerShape(bottomEnd = 12.dp)
                ) else Modifier
            )
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(24.dp),
                color = textColor,
                strokeWidth = 2.dp
            )
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                icon?.let {
                    Text(
                        text = it,
                        fontSize = 16.sp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = text,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 1.sp
                )
            }
        }
    }
}

/**
 * Section header with Victorian styling
 */
@Composable
fun VictorianSectionHeader(
    title: String,
    subtitle: String? = null,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "◇",
                color = Gold,
                fontSize = 14.sp
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = title,
                    color = TextSecondary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 1.sp
                )
                subtitle?.let {
                    Text(
                        text = it,
                        color = TextMuted,
                        fontSize = 11.sp,
                        letterSpacing = 2.sp
                    )
                }
            }
        }
    }
}

/**
 * Vignette overlay effect
 */
@Composable
fun VignetteOverlay(
    modifier: Modifier = Modifier,
    intensity: Float = 0.7f
) {
    Canvas(modifier = modifier) {
        val gradient = Brush.radialGradient(
            colors = listOf(
                Color.Transparent,
                Color.Black.copy(alpha = intensity)
            ),
            center = Offset(size.width / 2, size.height / 2),
            radius = size.maxDimension * 0.8f
        )
        drawRect(brush = gradient)
    }
}

/**
 * Status badge with faction colors
 */
@Composable
fun FactionBadge(
    faction: String,
    modifier: Modifier = Modifier
) {
    val (backgroundColor, text) = when (faction.lowercase()) {
        "worker" -> WorkerColor to "紡織工人"
        "factory" -> FactoryColor to "工廠主"
        "luddite" -> LudditeColor to "盧德派"
        "reformer" -> ReformerColor to "改革者"
        "mp" -> MPColor to "議員"
        "george_iii", "king" -> GeorgeIIIColor to "喬治三世"
        else -> CardBorder to faction
    }

    Surface(
        color = backgroundColor.copy(alpha = 0.2f),
        shape = RoundedCornerShape(4.dp),
        modifier = modifier.border(1.dp, backgroundColor.copy(alpha = 0.5f), RoundedCornerShape(4.dp))
    ) {
        Text(
            text = text,
            color = TextSecondary,
            fontSize = 12.sp,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

/**
 * Animated countdown timer display
 */
@Composable
fun VictorianTimer(
    remainingSeconds: Int,
    modifier: Modifier = Modifier
) {
    val minutes = remainingSeconds / 60
    val seconds = remainingSeconds % 60
    val isUrgent = remainingSeconds <= 30

    val pulseAlpha by animateFloatAsState(
        targetValue = if (isUrgent && remainingSeconds % 2 == 0) 1f else 0.7f,
        animationSpec = tween(500),
        label = "timerPulse"
    )

    Box(
        modifier = modifier
            .border(
                2.dp,
                if (isUrgent) Error.copy(alpha = pulseAlpha) else Gold.copy(alpha = 0.5f),
                RoundedCornerShape(8.dp)
            )
            .background(DarkOverlay80, RoundedCornerShape(8.dp))
            .padding(horizontal = 24.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "%02d:%02d".format(minutes, seconds),
            color = if (isUrgent) Error else Gold,
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace,
            letterSpacing = 4.sp
        )
    }
}

/**
 * Quote display with decorative styling
 */
@Composable
fun VictorianQuote(
    quote: String,
    attribution: String? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "「$quote」",
            color = TextSecondary,
            fontSize = 13.sp,
            textAlign = TextAlign.Center,
            fontFamily = FontFamily.Serif,
            lineHeight = 20.sp
        )
        attribution?.let {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "— $it",
                color = TextMuted,
                fontSize = 11.sp,
                textAlign = TextAlign.Center
            )
        }
    }
}
