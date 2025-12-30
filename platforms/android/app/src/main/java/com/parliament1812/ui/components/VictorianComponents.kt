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
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
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
 * Applies a Victorian parchment texture overlay (Canvas noise)
 */
@Composable
fun Modifier.paperSurface(
    alpha: Float = 0.05f
): Modifier = this.drawBehind {
    val noiseColor = Color(0xFF4E453C)
    drawRect(
        color = Parchment,
        alpha = 0.98f // Base paper color
    )
    // Simple noise simulation using random dots
    // In a real app, a tiled image texture would be better performance-wise
    val density = 0.8f // probability of dot
    val dotSize = 2.dp.toPx()
    
    // Draw subtle grain
    // Note: For performance, we stick to a very simple overlay or color modulation
    // Actual per-pixel noise is too heavy for drawBehind without a shader
    
    // Draw some random "fiber" lines
    val random = Random(123)
    repeat(10) {
        val startX = random.nextFloat() * size.width
        val startY = random.nextFloat() * size.height
        val endX = startX + (random.nextFloat() - 0.5f) * 50f
        val endY = startY + (random.nextFloat() - 0.5f) * 50f
        
        drawLine(
            color = noiseColor,
            start = Offset(startX, startY),
            end = Offset(endX, endY),
            strokeWidth = 1f,
            alpha = alpha
        )
    }
}

/**
 * Regency-era styled button with cut corner and metallic sheen animation
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
    
    // Metallic Sheen Animation
    val infiniteTransition = rememberInfiniteTransition(label = "sheen")
    val sheenProgress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(4000, easing = LinearEasing, delayMillis = 1000),
            repeatMode = RepeatMode.Restart
        ),
        label = "sheenProgress"
    )

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
        Box(contentAlignment = Alignment.Center) {
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
            
            // Sheen Overlay
            if (isPrimary && enabled) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val width = size.width
                    val height = size.height
                    val barWidth = 40f
                    
                    // The sheen moves from left to right
                    val offset = (width + barWidth * 2) * sheenProgress - barWidth
                    
                    rotate(20f) {
                        drawRect(
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Color.White.copy(alpha = 0.4f),
                                    Color.Transparent
                                ),
                                start = Offset(offset, 0f),
                                end = Offset(offset + barWidth, 0f)
                            ),
                            topLeft = Offset(offset, -height), // Extend top/bottom to cover rotation
                            size = Size(barWidth, height * 3) 
                        )
                    }
                }
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

// ============================================
// Victorian Oval Player Card (2-column grid style)
// ============================================

/**
 * Victorian oval player card for grid display
 * Used in WaitingRoomScreen with 2-column layout
 *
 * @param nickname Player's display name
 * @param roleType Role type string (e.g., "worker", "factory", "luddite", etc.)
 * @param isHost Whether this player is the room host
 * @param isReady Whether the player is ready
 * @param isCurrentUser Whether this is the current user's card
 * @param modifier Modifier for the card
 */
@Composable
fun VictorianOvalPlayerCard(
    nickname: String,
    roleType: String?,
    isHost: Boolean,
    isReady: Boolean,
    isCurrentUser: Boolean,
    modifier: Modifier = Modifier
) {
    // Determine status badge content
    val statusBadge: Triple<String, String, Color>? = when {
        isHost -> Triple("議長", "crown", Gold)
        isReady -> Triple("已就緒", "check", Color(0xFF4CAF50))
        roleType != null -> Triple("待就緒", "clock", Color(0xFFFF9800))
        else -> null
    }

    Column(
        modifier = modifier
            .background(
                CardBackgroundTranslucent,
                RoundedCornerShape(12.dp)
            )
            .border(
                width = if (isCurrentUser) 2.dp else 1.dp,
                brush = Brush.linearGradient(
                    colors = if (isCurrentUser) {
                        listOf(Gold.copy(alpha = 0.6f), Gold.copy(alpha = 0.3f))
                    } else {
                        listOf(Gold.copy(alpha = 0.15f), Gold.copy(alpha = 0.1f))
                    }
                ),
                shape = RoundedCornerShape(12.dp)
            )
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Victorian Oval Portrait Frame
        Box(
            modifier = Modifier.size(width = 90.dp, height = 110.dp),
            contentAlignment = Alignment.Center
        ) {
            // Victorian oval frame
            VictorianOvalFrame(
                modifier = Modifier.size(width = 80.dp, height = 98.dp)
            )

            // Portrait content (role image or initial letter)
            if (roleType != null) {
                CharacterPortraitSmall(
                    roleType = roleType,
                    modifier = Modifier,
                    size = 70.dp,
                    showBorder = false
                )
            } else {
                // Initial letter for unassigned players
                Box(
                    modifier = Modifier
                        .size(width = 70.dp, height = 85.dp)
                        .clip(HexagonShape())
                        .background(DarkBackground),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = nickname.take(1).uppercase(),
                        color = Gold,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            // Ready checkmark overlay removed as per user request (was blocking portrait)

        }

        Spacer(modifier = Modifier.height(8.dp))

        // Player name
        Text(
            text = nickname,
            color = TextPrimary,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
            maxLines = 1
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Role name (if assigned)
        Text(
            text = if (roleType != null) {
                getRoleDisplayName(roleType)
            } else {
                "等待選角"
            },
            color = if (roleType != null) GoldMuted else TextMuted,
            fontSize = if (roleType != null) 11.sp else 10.sp,
            textAlign = TextAlign.Center,
            maxLines = 1
        )

        // Status badge
        statusBadge?.let { (text, _, color) ->
            Spacer(modifier = Modifier.height(6.dp))
            Box(
                modifier = Modifier
                    .background(
                        color = color,
                        shape = RoundedCornerShape(50)
                    )
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = text,
                    color = if (color == Gold) DarkBackground else Color.White,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

/**
 * Victorian-style hexagonal gold frame component
 */
/**
 * Victorian-style hexagonal gold frame component with intricate details
 */
@Composable
fun VictorianOvalFrame(
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val width = size.width
        val height = size.height
        val centerX = width / 2
        val centerY = height / 2

        // Create hexagonal path (pointy-top orientation for portrait)
        fun createHexagonPath(scaleX: Float, scaleY: Float, offsetX: Float = 0f, offsetY: Float = 0f): Path {
            return Path().apply {
                for (i in 0..5) {
                    // Pointy-top hexagon: start at top
                    val angle = Math.PI / 3 * i - Math.PI / 2
                    val x = centerX + (width / 2 * scaleX) * cos(angle).toFloat() + offsetX
                    val y = centerY + (height / 2 * scaleY) * sin(angle).toFloat() + offsetY
                    if (i == 0) moveTo(x, y) else lineTo(x, y)
                }
                close()
            }
        }

        // Draw outer bevel (Shadow)
        val outerBevel = createHexagonPath(0.98f, 0.98f, 2f, 2f)
        drawPath(
            path = outerBevel,
            color = Color.Black.copy(alpha = 0.5f),
            style = Stroke(width = 4.dp.toPx())
        )

        // Draw main frame with metallic gradient
        val outerPath = createHexagonPath(0.95f, 0.95f)
        val metallicGradient = Brush.linearGradient(
            colors = listOf(
                MetallicGoldStop1,
                MetallicGoldStop2,
                MetallicGoldStop3,
                MetallicGoldStop4,
                MetallicGoldStop5
            ),
            start = Offset(0f, 0f),
            end = Offset(width, height)
        )
        
        drawPath(
            path = outerPath,
            brush = metallicGradient,
            style = Stroke(width = 5.dp.toPx())
        )

        // Draw inner decorative line
        val innerPath = createHexagonPath(0.85f, 0.85f)
        drawPath(
            path = innerPath,
            brush = Brush.linearGradient(
                colors = listOf(GoldDark, GoldLight),
                start = Offset(width, 0f),
                end = Offset(0f, height)
            ),
            style = Stroke(width = 1.pixel()) // Hairline
        )
        
        // Draw corner accents (Circles at vertices)
        for (i in 0..5) {
            val angle = Math.PI / 3 * i - Math.PI / 2
            val x = centerX + (width / 2 * 0.95f) * cos(angle).toFloat()
            val y = centerY + (height / 2 * 0.95f) * sin(angle).toFloat()
            
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(GoldLight, GoldDark)
                ),
                radius = 3.dp.toPx(),
                center = Offset(x, y)
            )
        }
    }
}

/**
 * Animated Fog of War overlay (Cloud effect)
 */
@Composable
fun FogOfWarOverlay(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Box(modifier = modifier) {
        // Background content
        content()
        
        // Cloud layers
        // Note: For real production, use R.drawable.cloud_texture with alpha
        // Here we simulate with moving gradients/shapes
        
        val infiniteTransition = rememberInfiniteTransition(label = "clouds")
        val cloudOffset by infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = 1000f,
            animationSpec = infiniteRepeatable(
                animation = tween(60000, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            ),
            label = "cloudOffset"
        )
        
        Canvas(modifier = Modifier.fillMaxSize().alpha(0.3f)) {
            val cloudColor = Color(0xFF1A1A1A) // Dark smoke/fog
            
            // Draw some "cloud" shapes moving slowly
            val scale = size.minDimension / 2 // Base scale
            
            withTransform({
                translate(left = -cloudOffset % size.width, top = 0f)
            }) {
                // Simulating clouds with overlapped large circles
                for(i in 0..5) {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(cloudColor.copy(alpha=0.8f), Color.Transparent),
                            radius = scale * 1.5f
                        ),
                        center = Offset(i * scale * 0.8f, size.height * 0.5f),
                        radius = scale
                    )
                }
                // Second row to fill gaps
                for(i in 0..5) {
                    drawCircle(
                        brush = Brush.radialGradient(
                            colors = listOf(cloudColor.copy(alpha=0.6f), Color.Transparent),
                            radius = scale * 1.2f
                        ),
                        center = Offset(i * scale * 0.8f + scale/2, size.height * 0.2f),
                        radius = scale * 0.8f
                    )
                }
            }
        }
        
        // Vignette on top
        VignetteOverlay(modifier = Modifier.matchParentSize())
    }
}

private fun Int.pixel() = this.dp.value // Simplified pixel conversion helper for this snippet scope only if needed, but actually Canvas scope has density. 
// Correct way in DrawScope is .dp.toPx() which is extension available if we import `toPx`.
// But we are in DrawScope, so local `dp.toPx()` works if we have import.
// Let's rely on standard `toPx` on Dp.

private fun DrawScope.pixel(dp: Dp) = dp.toPx()

/**
 * Hexagonal Shape for clipping and borders
 * Creates a hexagon with pointy-top orientation
 */
class HexagonShape : Shape {
    override fun createOutline(
        size: Size,
        layoutDirection: LayoutDirection,
        density: Density
    ): Outline {
        val path = Path().apply {
            val centerX = size.width / 2
            val centerY = size.height / 2
            val radiusX = size.width / 2
            val radiusY = size.height / 2

            for (i in 0..5) {
                // Pointy-top hexagon: start at top
                val angle = Math.PI / 3 * i - Math.PI / 2
                val x = centerX + radiusX * cos(angle).toFloat()
                val y = centerY + radiusY * sin(angle).toFloat()
                if (i == 0) moveTo(x, y) else lineTo(x, y)
            }
            close()
        }
        return Outline.Generic(path)
    }
}

// Helper function to get role display name
private fun getRoleDisplayName(roleType: String): String {
    return when (roleType.lowercase()) {
        "worker" -> "湯瑪斯"
        "factory_owner", "factory" -> "理查·威爾森"
        "luddite" -> "喬治"
        "reformer" -> "羅伯特·烏爾文"
        "mp" -> "威廉·菲茨傑拉德"
        "george_iii", "king" -> "喬治三世"
        else -> roleType
    }
}
