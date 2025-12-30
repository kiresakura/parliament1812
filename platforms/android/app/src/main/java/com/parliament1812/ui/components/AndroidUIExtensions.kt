package com.parliament1812.ui.components

import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

// MARK: - Blur Effect (Android 12+)
fun Modifier.victorianBlur(
    radiusX: Float = 10f,
    radiusY: Float = 10f
): Modifier = composed {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        this.graphicsLayer {
            renderEffect = android.graphics.RenderEffect.createBlurEffect(
                radiusX, radiusY, android.graphics.Shader.TileMode.MIRROR
            ).asComposeRenderEffect()
        }
    } else {
        this.background(Color.Black.copy(alpha = 0.5f))
    }
}

// MARK: - Texture Blending
fun Modifier.parchmentBlend(
    baseColor: Color = Color(0xFFF5EDD9),
    textureColor: Color = Color(0xFF402E1F)
): Modifier = drawBehind {
    drawRect(color = baseColor)
    drawRect(
        color = textureColor,
        alpha = 0.05f,
        blendMode = BlendMode.Multiply
    )
}

// MARK: - Staggered Entry Animation
fun Modifier.staggeredEntry(
    index: Int,
    visible: Boolean = true
): Modifier = composed {
    val animatedAlpha by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = tween(300, delayMillis = index * 50),
        label = "alpha"
    )

    val animatedRotation by animateFloatAsState(
        targetValue = if (visible) 0f else -10f,
        animationSpec = tween(400, delayMillis = index * 50),
        label = "rotation"
    )

    val animatedTranslation by animateFloatAsState(
        targetValue = if (visible) 0f else 50f,
        animationSpec = tween(400, delayMillis = index * 50),
        label = "translation"
    )

    this.graphicsLayer {
        alpha = animatedAlpha
        rotationX = animatedRotation
        translationY = animatedTranslation
    }
}

// MARK: - Deep Shadow
fun Modifier.victorianShadow(
    elevation: Dp = 8.dp
): Modifier = drawBehind {
    val shadowColor = Color.Black.copy(alpha = 0.4f)
    val spread = elevation.toPx()

    drawIntoCanvas { canvas ->
        val paint = Paint()
        val frameworkPaint = paint.asFrameworkPaint()
        frameworkPaint.color = shadowColor.toArgb()

        val rect = Rect(0f, 0f, size.width, size.height)

        // Deep shadow (close, sharp)
        frameworkPaint.setShadowLayer(
            spread * 0.5f,
            0f,
            spread * 0.5f,
            shadowColor.toArgb()
        )
        canvas.drawRect(rect, paint)

        // Ambient shadow (wide, soft)
        frameworkPaint.setShadowLayer(
            spread * 1.5f,
            0f,
            spread,
            shadowColor.copy(alpha = 0.2f).toArgb()
        )
        canvas.drawRect(rect, paint)
    }
}

// MARK: - Haptic Helper
fun Modifier.victorianHapticFeedback(
    onClick: () -> Unit = {}
): Modifier = composed {
    val view = LocalView.current
    this.clickable {
        view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
        onClick()
    }
}
