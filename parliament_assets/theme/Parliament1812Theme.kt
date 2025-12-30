// Parliament1812Theme.kt
// 1812 國會風雲 - Android Theme Configuration
// Based on Figma Design System

package com.parliament1812.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// ============================================
// MARK: - Color Palette
// ============================================
object Parliament1812Colors {
    // Primary Colors
    val DarkNavy = Color(0xFF1A1A2E)          // PRIMARY BACKGROUND
    val SecondaryNavy = Color(0xFF16213E)     // CARD BACKGROUNDS
    val DarkBrown = Color(0xFF1A1614)         // Alternative dark background
    val CardBrown = Color(0xFF241B14)         // Card background variant
    
    // Accent Colors
    val AntiqueGold = Color(0xFFD4AF37)       // PRIMARY ACCENT
    val SaddleBrown = Color(0xFF8B4513)       // SECONDARY ACCENT
    val MutedGold = Color(0xFFB8941F)         // Gradient gold
    
    // Text Colors
    val ParchmentCream = Color(0xFFF5E6D3)    // PRIMARY TEXT
    val MutedText = Color(0xFFB8A07E)         // SECONDARY TEXT
    val SubtleText = Color(0xFF8B7753)        // Tertiary text
    
    // Political Party Colors
    val ToryBlue = Color(0xFF1E3A5F)          // TORY PARTY
    val WhigOrange = Color(0xFFCC7722)        // WHIG PARTY
    val Neutral = Color(0xFF8B7753)           // NEUTRAL
    
    // Voting Colors
    val AyeGreen = Color(0xFF2D5A27)          // AYE/SUCCESS
    val NayCrimson = Color(0xFF8B2500)        // NAY/DANGER
    
    // Wax Seal Colors
    val SealDark = Color(0xFF6E1E00)
    val SealMid = Color(0xFF8B2500)
    val SealLight = Color(0xFFA3320B)
    
    // With Alpha
    val GoldBorder = AntiqueGold.copy(alpha = 0.3f)
    val CardShadow = Color.Black.copy(alpha = 0.5f)
}

// ============================================
// MARK: - Typography
// ============================================
// Note: Add Georgia or similar serif font to res/font/
val GeorgiaFamily = FontFamily(
    Font(R.font.georgia_regular, FontWeight.Normal),
    Font(R.font.georgia_bold, FontWeight.Bold),
)

// Fallback if Georgia not available
val SerifFamily = FontFamily.Serif

object Parliament1812Typography {
    val TitleLarge = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 48.sp,
        letterSpacing = 8.sp
    )
    
    val TitleMedium = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 32.sp,
        letterSpacing = 6.sp
    )
    
    val TitleSmall = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        letterSpacing = 4.sp
    )
    
    val Heading = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        letterSpacing = 2.sp
    )
    
    val Body = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp
    )
    
    val Caption = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp
    )
    
    val Small = TextStyle(
        fontFamily = SerifFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp
    )
    
    val CodeLarge = TextStyle(
        fontFamily = FontFamily.Monospace,
        fontWeight = FontWeight.Normal,
        fontSize = 24.sp,
        letterSpacing = 8.sp
    )
}

// ============================================
// MARK: - Custom Shapes
// ============================================
object Parliament1812Shapes {
    // Cut corner button shape
    val ButtonShape = CutCornerShape(
        topStart = 0.dp,
        topEnd = 0.dp,
        bottomStart = 0.dp,
        bottomEnd = 12.dp
    )
    
    // Card shape with slight rounded corners
    val CardShape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp)
    
    // Hexagon shape for badges
    val HexagonShape = GenericShape { size, _ ->
        val centerX = size.width / 2
        val centerY = size.height / 2
        val radius = minOf(size.width, size.height) / 2
        
        moveTo(
            centerX + radius * kotlin.math.cos(-Math.PI / 2).toFloat(),
            centerY + radius * kotlin.math.sin(-Math.PI / 2).toFloat()
        )
        
        for (i in 1..5) {
            val angle = -Math.PI / 2 + i * Math.PI / 3
            lineTo(
                centerX + radius * kotlin.math.cos(angle).toFloat(),
                centerY + radius * kotlin.math.sin(angle).toFloat()
            )
        }
        close()
    }
    
    // Slanted button shapes for mode toggle
    val CreateButtonShape = GenericShape { size, _ ->
        moveTo(size.width * 0.1f, 0f)
        lineTo(size.width, 0f)
        lineTo(size.width * 0.9f, size.height)
        lineTo(0f, size.height)
        close()
    }
    
    val JoinButtonShape = GenericShape { size, _ ->
        moveTo(0f, 0f)
        lineTo(size.width * 0.9f, 0f)
        lineTo(size.width, size.height)
        lineTo(size.width * 0.1f, size.height)
        close()
    }
}

// ============================================
// MARK: - Material3 Color Scheme
// ============================================
private val Parliament1812ColorScheme = darkColorScheme(
    primary = Parliament1812Colors.AntiqueGold,
    onPrimary = Parliament1812Colors.DarkNavy,
    primaryContainer = Parliament1812Colors.MutedGold,
    onPrimaryContainer = Parliament1812Colors.DarkNavy,
    
    secondary = Parliament1812Colors.SaddleBrown,
    onSecondary = Parliament1812Colors.ParchmentCream,
    secondaryContainer = Parliament1812Colors.CardBrown,
    onSecondaryContainer = Parliament1812Colors.ParchmentCream,
    
    tertiary = Parliament1812Colors.ToryBlue,
    onTertiary = Parliament1812Colors.ParchmentCream,
    
    background = Parliament1812Colors.DarkBrown,
    onBackground = Parliament1812Colors.ParchmentCream,
    
    surface = Parliament1812Colors.CardBrown,
    onSurface = Parliament1812Colors.ParchmentCream,
    surfaceVariant = Parliament1812Colors.SecondaryNavy,
    onSurfaceVariant = Parliament1812Colors.MutedText,
    
    error = Parliament1812Colors.NayCrimson,
    onError = Parliament1812Colors.ParchmentCream,
    
    outline = Parliament1812Colors.GoldBorder,
    outlineVariant = Parliament1812Colors.SubtleText,
)

// ============================================
// MARK: - Theme Composable
// ============================================
@Composable
fun Parliament1812Theme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = Parliament1812ColorScheme,
        typography = Typography(
            displayLarge = Parliament1812Typography.TitleLarge,
            displayMedium = Parliament1812Typography.TitleMedium,
            displaySmall = Parliament1812Typography.TitleSmall,
            headlineLarge = Parliament1812Typography.Heading,
            headlineMedium = Parliament1812Typography.Body,
            bodyLarge = Parliament1812Typography.Body,
            bodyMedium = Parliament1812Typography.Caption,
            bodySmall = Parliament1812Typography.Small,
        ),
        content = content
    )
}

// ============================================
// MARK: - Party Enum
// ============================================
enum class Party(
    val color: Color,
    val nameChinese: String,
    val nameEnglish: String
) {
    TORY(Parliament1812Colors.ToryBlue, "托利黨", "TORY PARTY"),
    WHIG(Parliament1812Colors.WhigOrange, "輝格黨", "WHIG PARTY"),
    NEUTRAL(Parliament1812Colors.Neutral, "中立", "NEUTRAL")
}

// ============================================
// MARK: - Constants
// ============================================
object Parliament1812Dimens {
    // Spacing
    val SpacingXS = 4.dp
    val SpacingS = 8.dp
    val SpacingM = 16.dp
    val SpacingL = 24.dp
    val SpacingXL = 32.dp
    val SpacingXXL = 48.dp
    
    // Padding
    val PaddingButton = 14.dp
    val PaddingCard = 16.dp
    val PaddingScreen = 24.dp
    
    // Borders
    val BorderThin = 1.dp
    val BorderMedium = 2.dp
    val BorderThick = 4.dp
    
    // Corner radius
    val CornerSmall = 4.dp
    val CornerMedium = 8.dp
    val CornerLarge = 12.dp
    val CornerXL = 16.dp
    
    // Button cut corner
    val ButtonCutCorner = 12.dp
    
    // Icon sizes
    val IconSmall = 16.dp
    val IconMedium = 24.dp
    val IconLarge = 32.dp
    val IconXL = 48.dp
    
    // Touch targets
    val MinTouchTarget = 44.dp
}

// ============================================
// MARK: - Shadow & Elevation
// ============================================
object Parliament1812Elevation {
    val Card = 8.dp
    val Button = 4.dp
    val Dialog = 16.dp
    val Overlay = 24.dp
}

// ============================================
// MARK: - Animation Durations
// ============================================
object Parliament1812Animation {
    const val FastMs = 150
    const val NormalMs = 300
    const val SlowMs = 500
    const val VerySlowMs = 800
}

// ============================================
// MARK: - Gradients
// ============================================
object Parliament1812Gradients {
    val GoldButton = listOf(
        Parliament1812Colors.AntiqueGold,
        Parliament1812Colors.MutedGold
    )
    
    val CardBackground = listOf(
        Parliament1812Colors.CardBrown.copy(alpha = 0.95f),
        Parliament1812Colors.CardBrown.copy(alpha = 0.85f)
    )
    
    val Vignette = listOf(
        Color.Transparent,
        Color.Transparent,
        Parliament1812Colors.DarkBrown.copy(alpha = 0.8f)
    )
}

// ============================================
// MARK: - String Resources (Chinese)
// ============================================
object Parliament1812Strings {
    // Home Screen
    const val AppTitle = "1812"
    const val AppSubtitleChinese = "國會風雲"
    const val AppSubtitleEnglish = "Parliament Debates"
    const val RegencyEra = "REGENCY ERA"
    const val BritishParliament = "1812 • British Parliament"
    
    // Mode Toggle
    const val CreateRoom = "建立房間"
    const val JoinRoom = "加入房間"
    const val CreateEnglish = "Create"
    const val JoinEnglish = "Join"
    
    // Input Fields
    const val NicknameChinese = "您的暱稱"
    const val NicknameEnglish = "Your Nickname"
    const val NicknamePlaceholder = "輸入暱稱..."
    const val RoomCodeChinese = "房間代碼"
    const val RoomCodeEnglish = "Room Code"
    const val RoomCodePlaceholder = "XXXXXX"
    
    // Buttons
    const val CreateMeeting = "建立新會議"
    const val EnterChamber = "進入議事廳"
    const val StartGame = "開始遊戲"
    const val Ready = "準備就緒"
    
    // Atmospheric
    const val Tagline = "「在攝政王的注視下，國會的權力鬥爭即將展開」"
    const val TaglineEnglish = "Under the Prince Regent's gaze..."
    
    // Waiting Room
    const val WaitingRoom = "等候大廳"
    const val MembersPresent = "在場成員"
    const val CopyCode = "複製代碼"
    const val Host = "主持"
    const val ReadyStatus = "準備"
    const val Waiting = "等待中"
    
    // Role Reveal
    const val YourRole = "您的身份"
    const val Objective = "您的目標"
    const val Allies = "已知盟友"
    const val HideRole = "隱藏身份"
    const val ShowRole = "顯示身份"
    const val TopSecret = "TOP SECRET"
    
    // Voting
    const val VotingTitle = "議案表決"
    const val Aye = "贊成"
    const val AyeEnglish = "AYE"
    const val Nay = "反對"
    const val NayEnglish = "NAY"
    const val Abstain = "棄權"
    const val AbstainEnglish = "ABSTAIN"
    const val VoteRecorded = "已記錄"
    const val Approved = "APPROVED"
    const val Rejected = "REJECTED"
    
    // Party Names
    const val ToryChinese = "托利黨"
    const val ToryEnglish = "TORY PARTY"
    const val WhigChinese = "輝格黨"
    const val WhigEnglish = "WHIG PARTY"
    const val NeutralChinese = "中立"
    const val NeutralEnglish = "NEUTRAL"
    
    // Errors
    const val EnterNickname = "請輸入您的暱稱"
    const val EnterRoomCode = "請輸入房間代碼"
    const val ConnectionError = "連線錯誤"
    const val RoomNotFound = "找不到房間"
    const val NFCRequired = "請將 NFC 卡片靠近手機"
}
