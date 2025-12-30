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
 * CharacterPortrait - 文明6風格的角色肖像組件（六邊形框架）
 *
 * 用於顯示角色畫像，簡潔六邊形設計
 */
@Composable
fun CharacterPortrait(
    roleType: String,
    modifier: Modifier = Modifier,
    size: Dp = 120.dp
) {
    val context = LocalContext.current
    val portraitRes = getPortraitResource(roleType)

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }

    // Hexagonal shape for the portrait
    val hexagonShape = remember { HexagonShape() }

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center
    ) {
        // Simple gold border frame (hexagonal)
        Box(
            modifier = Modifier
                .size(size)
                .border(
                    width = 3.dp,
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Gold,
                            GoldDark,
                            Gold
                        )
                    ),
                    shape = hexagonShape
                ),
            contentAlignment = Alignment.Center
        ) {
            // Portrait image clipped to hexagon
            portraitDrawable?.let { drawable ->
                Image(
                    painter = rememberDrawablePainter(drawable = drawable),
                    contentDescription = "角色肖像",
                    modifier = Modifier
                        .size(size - 6.dp)
                        .clip(hexagonShape),
                    contentScale = ContentScale.Crop
                )
            }
        }
    }
}

/**
 * CharacterPortraitSmall - 小型版本用於列表和頭像（六邊形版本）
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

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }

    // Use hexagonal shape
    val hexagonShape = remember { HexagonShape() }

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
                        shape = hexagonShape
                    )
                } else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        // Portrait only - no icon overlay
        portraitDrawable?.let { drawable ->
            Image(
                painter = rememberDrawablePainter(drawable = drawable),
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(hexagonShape),
                contentScale = ContentScale.Crop
            )
        }
    }
}

/**
 * CharacterPortraitCard - 角色卡片版本（簡潔六邊形框架）
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

    // Use rememberDrawablePainter for layer-list XML drawables
    val portraitDrawable = remember(portraitRes) {
        ContextCompat.getDrawable(context, portraitRes)
    }

    // Use hexagonal shape
    val hexagonShape = remember { HexagonShape() }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Main portrait with hexagonal frame
        Box(
            modifier = Modifier
                .size(160.dp)
                .border(
                    width = 3.dp,
                    brush = Brush.linearGradient(
                        colors = listOf(Gold, GoldDark, Gold)
                    ),
                    shape = hexagonShape
                ),
            contentAlignment = Alignment.Center
        ) {
            // Portrait only - no icon overlay
            portraitDrawable?.let { drawable ->
                Image(
                    painter = rememberDrawablePainter(drawable = drawable),
                    contentDescription = "角色肖像",
                    modifier = Modifier
                        .size(154.dp)
                        .clip(hexagonShape),
                    contentScale = ContentScale.Crop
                )
            }
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
