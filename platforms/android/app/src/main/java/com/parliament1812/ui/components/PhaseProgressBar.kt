package com.parliament1812.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.parliament1812.ui.theme.*
import kotlinx.coroutines.delay
import kotlin.math.max

/**
 * Game phase info data class
 */
data class PhaseInfo(
    val phase: Int,
    val nameZh: String,
    val nameEn: String,
    val description: String
) {
    companion object {
        fun fromPhase(phase: Int): PhaseInfo = when (phase) {
            1 -> PhaseInfo(1, "等待中", "WAITING", "等待更多議員加入...")
            2 -> PhaseInfo(2, "角色研究", "PREPARATION", "研究您的角色背景")
            3 -> PhaseInfo(3, "私下密謀", "CONSPIRACY", "與盟友私下交流")
            4 -> PhaseInfo(4, "開場陳述", "OPENING", "各方代表發表開場陳述")
            5 -> PhaseInfo(5, "突發事件", "SUDDEN EVENT", "突發事件打破平靜")
            6 -> PhaseInfo(6, "自由辯論", "FREE DEBATE", "說服、質疑、反駁！")
            7 -> PhaseInfo(7, "突發事件", "SUDDEN EVENT", "又一個突發事件")
            8 -> PhaseInfo(8, "第一輪投票", "FIRST VOTE", "匿名投票進行中")
            9 -> PhaseInfo(9, "最後攻防", "FINAL ARGUMENTS", "最後的說服機會")
            10 -> PhaseInfo(10, "記名投票", "ROLL CALL VOTE", "每一票都將被記錄")
            11 -> PhaseInfo(11, "結果揭曉", "REVELATION", "揭曉秘密任務")
            12 -> PhaseInfo(12, "遊戲結束", "FINISHED", "遊戲已結束")
            else -> PhaseInfo(phase, "未知階段", "UNKNOWN", "")
        }
    }
}

/**
 * Victorian-styled phase progress bar with countdown timer
 * Shows current phase name, remaining time, and progress through all phases
 */
@Composable
fun PhaseProgressBar(
    currentPhase: Int,
    timerEndAt: Long?,
    timerDuration: Int,
    modifier: Modifier = Modifier
) {
    val phaseInfo = PhaseInfo.fromPhase(currentPhase)
    val totalPhases = 12
    val progress = currentPhase.toFloat() / totalPhases

    // Calculate remaining time
    var remainingSeconds by remember { mutableIntStateOf(0) }

    LaunchedEffect(timerEndAt) {
        while (timerEndAt != null) {
            val now = System.currentTimeMillis()
            remainingSeconds = max(0, ((timerEndAt - now) / 1000).toInt())
            if (remainingSeconds <= 0) break
            delay(1000)
        }
    }

    val isUrgent = remainingSeconds in 1..30
    val pulseAlpha by animateFloatAsState(
        targetValue = if (isUrgent && remainingSeconds % 2 == 0) 1f else 0.7f,
        animationSpec = tween(500),
        label = "urgentPulse"
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        DarkOverlay80,
                        DarkBackground.copy(alpha = 0.95f)
                    )
                ),
                shape = RoundedCornerShape(12.dp)
            )
            .border(
                1.dp,
                Gold.copy(alpha = 0.3f),
                RoundedCornerShape(12.dp)
            )
            .padding(16.dp)
    ) {
        // Phase name row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = phaseInfo.nameZh,
                    color = Gold,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )
                Text(
                    text = phaseInfo.nameEn,
                    color = TextMuted,
                    fontSize = 11.sp,
                    letterSpacing = 2.sp
                )
            }

            // Countdown timer
            if (timerEndAt != null && remainingSeconds > 0) {
                CountdownTimerDisplay(
                    remainingSeconds = remainingSeconds,
                    isUrgent = isUrgent,
                    pulseAlpha = pulseAlpha
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Progress bar
        PhaseProgressIndicator(
            currentPhase = currentPhase,
            totalPhases = totalPhases,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Phase description
        Text(
            text = phaseInfo.description,
            color = TextSecondary,
            fontSize = 12.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/**
 * Compact countdown timer display
 */
@Composable
private fun CountdownTimerDisplay(
    remainingSeconds: Int,
    isUrgent: Boolean,
    pulseAlpha: Float,
    modifier: Modifier = Modifier
) {
    val minutes = remainingSeconds / 60
    val seconds = remainingSeconds % 60

    Box(
        modifier = modifier
            .border(
                2.dp,
                if (isUrgent) Error.copy(alpha = pulseAlpha) else Gold.copy(alpha = 0.5f),
                RoundedCornerShape(8.dp)
            )
            .background(DarkOverlay80, RoundedCornerShape(8.dp))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "%02d:%02d".format(minutes, seconds),
            color = if (isUrgent) Error else Gold,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace,
            letterSpacing = 2.sp
        )
    }
}

/**
 * Phase progress indicator showing dots for each phase
 */
@Composable
private fun PhaseProgressIndicator(
    currentPhase: Int,
    totalPhases: Int,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.height(24.dp)) {
        // Background track
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .align(Alignment.Center)
        ) {
            // Background line
            drawLine(
                color = CardBorder,
                start = Offset(0f, size.height / 2),
                end = Offset(size.width, size.height / 2),
                strokeWidth = 2.dp.toPx(),
                cap = StrokeCap.Round
            )

            // Progress line
            val progress = (currentPhase - 1).toFloat() / (totalPhases - 1)
            drawLine(
                brush = Brush.horizontalGradient(
                    colors = listOf(Gold, GoldLight)
                ),
                start = Offset(0f, size.height / 2),
                end = Offset(size.width * progress, size.height / 2),
                strokeWidth = 3.dp.toPx(),
                cap = StrokeCap.Round
            )
        }

        // Phase dots
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            for (phase in 1..totalPhases) {
                val isCompleted = phase < currentPhase
                val isCurrent = phase == currentPhase
                val dotColor = when {
                    isCompleted -> Gold
                    isCurrent -> GoldLight
                    else -> CardBorder
                }
                val dotSize = if (isCurrent) 12.dp else 8.dp

                Box(
                    modifier = Modifier
                        .size(dotSize)
                        .clip(RoundedCornerShape(50))
                        .background(dotColor)
                        .then(
                            if (isCurrent) Modifier.border(
                                2.dp,
                                Gold.copy(alpha = 0.5f),
                                RoundedCornerShape(50)
                            ) else Modifier
                        )
                )
            }
        }
    }
}

/**
 * Compact inline timer for GameScreen header
 */
@Composable
fun CompactPhaseTimer(
    currentPhase: Int,
    timerEndAt: Long?,
    modifier: Modifier = Modifier
) {
    val phaseInfo = PhaseInfo.fromPhase(currentPhase)
    var remainingSeconds by remember { mutableIntStateOf(0) }

    LaunchedEffect(timerEndAt) {
        while (timerEndAt != null) {
            val now = System.currentTimeMillis()
            remainingSeconds = max(0, ((timerEndAt - now) / 1000).toInt())
            if (remainingSeconds <= 0) break
            delay(1000)
        }
    }

    val isUrgent = remainingSeconds in 1..30
    val minutes = remainingSeconds / 60
    val seconds = remainingSeconds % 60

    Row(
        modifier = modifier
            .background(DarkOverlay80, RoundedCornerShape(8.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = phaseInfo.nameZh,
            color = Gold,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )

        if (timerEndAt != null && remainingSeconds > 0) {
            Text(
                text = "%02d:%02d".format(minutes, seconds),
                color = if (isUrgent) Error else TextSecondary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace
            )
        }
    }
}
