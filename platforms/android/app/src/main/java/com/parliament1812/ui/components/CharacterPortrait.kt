package com.parliament1812.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.google.accompanist.drawablepainter.rememberDrawablePainter
import com.parliament1812.R
import com.parliament1812.ui.theme.*

/**
 * CharacterPortrait - 文明6風格的角色肖像組件
 *
 * 用於替代原本的 Emoji 顯示，提供更專業的視覺效果
 */
@Composable
fun CharacterPortrait(
    roleType: String,
    modifier: Modifier = Modifier,
    size: Dp = 120.dp,
    showIcon: Boolean = true,
    showGlow: Boolean = true
) {
    val context = LocalContext.current
    val portraitRes = getPortraitResource(roleType)
    val iconRes = getRoleIconResource(roleType)
    val roleColor = getRoleColor(roleType)

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }
    val iconDrawable = remember(iconRes) {
        ContextCompat.getDrawable(context, iconRes)
    }

    // Subtle pulsing glow animation
    val infiniteTransition = rememberInfiniteTransition(label = "portraitGlow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowAlpha"
    )

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center
    ) {
        // Outer glow effect
        if (showGlow) {
            Box(
                modifier = Modifier
                    .size(size * 1.1f)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                roleColor.copy(alpha = glowAlpha * 0.5f),
                                roleColor.copy(alpha = glowAlpha * 0.2f),
                                Color.Transparent
                            )
                        )
                    )
            )
        }

        // Portrait background with gold frame effect
        portraitDrawable?.let { drawable ->
            Image(
                painter = rememberDrawablePainter(drawable = drawable),
                contentDescription = "角色肖像背景",
                modifier = Modifier
                    .size(size)
                    .shadow(8.dp, CircleShape)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )
        }

        // Role icon overlay
        if (showIcon) {
            iconDrawable?.let { drawable ->
                Image(
                    painter = rememberDrawablePainter(drawable = drawable),
                    contentDescription = "角色圖標",
                    modifier = Modifier
                        .size(size * 0.5f)
                        .align(Alignment.Center),
                    contentScale = ContentScale.Fit
                )
            }
        }
    }
}

/**
 * CharacterPortraitSmall - 小型版本用於列表和頭像
 */
@Composable
fun CharacterPortraitSmall(
    roleType: String,
    modifier: Modifier = Modifier,
    size: Dp = 48.dp,
    showBorder: Boolean = true
) {
    val context = LocalContext.current
    val portraitRes = getPortraitResource(roleType)
    val iconRes = getRoleIconResource(roleType)
    val roleColor = getRoleColor(roleType)

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }
    val iconDrawable = remember(iconRes) {
        ContextCompat.getDrawable(context, iconRes)
    }

    Box(
        modifier = modifier
            .size(size)
            .then(
                if (showBorder) {
                    Modifier.border(
                        width = 2.dp,
                        brush = Brush.linearGradient(
                            colors = listOf(Gold, GoldDark, Gold)
                        ),
                        shape = CircleShape
                    )
                } else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        // Background
        portraitDrawable?.let { drawable ->
            Image(
                painter = rememberDrawablePainter(drawable = drawable),
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )
        }

        // Icon
        iconDrawable?.let { drawable ->
            Image(
                painter = rememberDrawablePainter(drawable = drawable),
                contentDescription = null,
                modifier = Modifier.size(size * 0.55f),
                contentScale = ContentScale.Fit
            )
        }
    }
}

/**
 * CharacterPortraitCard - 角色卡片版本，帶有完整框架
 */
@Composable
fun CharacterPortraitCard(
    roleType: String,
    roleName: String,
    roleTitle: String,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val portraitRes = getPortraitResource(roleType)
    val iconRes = getRoleIconResource(roleType)
    val roleColor = getRoleColor(roleType)

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }
    val iconDrawable = remember(iconRes) {
        ContextCompat.getDrawable(context, iconRes)
    }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Main portrait with decorative frame
        Box(
            modifier = Modifier.size(180.dp),
            contentAlignment = Alignment.Center
        ) {
            // Outer decorative frame
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .shadow(12.dp, CircleShape)
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color(0xFFFFD700),
                                Color(0xFFB8860B),
                                Color(0xFFDAA520),
                                Color(0xFFB8860B),
                                Color(0xFFFFD700)
                            )
                        ),
                        CircleShape
                    )
            )

            // Inner frame
            Box(
                modifier = Modifier
                    .size(170.dp)
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color(0xFF8B6914),
                                Color(0xFFFFD700),
                                Color(0xFF8B6914)
                            )
                        ),
                        CircleShape
                    )
            )

            // Portrait background
            portraitDrawable?.let { drawable ->
                Image(
                    painter = rememberDrawablePainter(drawable = drawable),
                    contentDescription = "角色肖像",
                    modifier = Modifier
                        .size(160.dp)
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
            }

            // Role icon
            iconDrawable?.let { drawable ->
                Image(
                    painter = rememberDrawablePainter(drawable = drawable),
                    contentDescription = null,
                    modifier = Modifier.size(80.dp),
                    contentScale = ContentScale.Fit
                )
            }

            // Corner ornaments
            VictorianCornerOrnament(
                modifier = Modifier
                    .size(24.dp)
                    .align(Alignment.TopStart)
                    .offset(x = 10.dp, y = 10.dp),
                corner = Corner.TopLeft,
                color = Gold
            )
            VictorianCornerOrnament(
                modifier = Modifier
                    .size(24.dp)
                    .align(Alignment.TopEnd)
                    .offset(x = (-10).dp, y = 10.dp),
                corner = Corner.TopRight,
                color = Gold
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Gold divider
        GoldDivider(
            modifier = Modifier.width(120.dp),
            withDiamond = true
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Role name
        Text(
            text = roleName,
            color = TextPrimary,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 2.sp
        )

        Text(
            text = roleTitle,
            color = GoldAccent,
            fontSize = 14.sp,
            letterSpacing = 3.sp
        )
    }
}

// Helper functions
private fun getPortraitResource(roleType: String): Int {
    return when (roleType.lowercase()) {
        "worker" -> R.drawable.portrait_worker
        "factory_owner", "factory" -> R.drawable.portrait_factory_owner
        "luddite" -> R.drawable.portrait_luddite
        "reformer" -> R.drawable.portrait_reformer
        "mp" -> R.drawable.portrait_mp
        "george_iii", "king" -> R.drawable.portrait_george_iii
        else -> R.drawable.portrait_default
    }
}

private fun getRoleIconResource(roleType: String): Int {
    return when (roleType.lowercase()) {
        "worker" -> R.drawable.ic_role_worker
        "factory_owner", "factory" -> R.drawable.ic_role_factory
        "luddite" -> R.drawable.ic_role_luddite
        "reformer" -> R.drawable.ic_role_reformer
        "mp" -> R.drawable.ic_role_mp
        "george_iii", "king" -> R.drawable.ic_role_george_iii
        else -> R.drawable.ic_role_worker // default
    }
}

private fun getRoleColor(roleType: String): Color {
    return when (roleType.lowercase()) {
        "worker" -> WorkerColor
        "factory_owner", "factory" -> FactoryColor
        "luddite" -> LudditeColor
        "reformer" -> ReformerColor
        "mp" -> MPColor
        "george_iii", "king" -> GeorgeIIIColor
        else -> GoldMuted
    }
}
