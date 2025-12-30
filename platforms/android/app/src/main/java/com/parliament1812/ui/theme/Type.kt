package com.parliament1812.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.parliament1812.R

// Custom Fonts for Regency Era Theme
val CinzelDecorativeFont = FontFamily(
    Font(R.font.cinzel_decorative_bold, FontWeight.Bold)
)

val NotoSerifSCFont = FontFamily(
    Font(R.font.noto_serif_sc_regular, FontWeight.Normal)
)

val BodoniModaFont = FontFamily(
    Font(R.font.bodoni_moda_bold, FontWeight.Bold)
)

// Fallback fonts
val SerifFont = FontFamily.Serif
val SansFont = FontFamily.Default

val Typography = Typography(
    // Display - Large decorative titles (e.g., "1812") - Use Cinzel Decorative
    displayLarge = TextStyle(
        fontFamily = CinzelDecorativeFont,
        fontWeight = FontWeight.Bold,
        fontSize = 72.sp,
        lineHeight = 80.sp,
        letterSpacing = (-0.5).sp
    ),
    displayMedium = TextStyle(
        fontFamily = CinzelDecorativeFont,
        fontWeight = FontWeight.Bold,
        fontSize = 52.sp,
        lineHeight = 60.sp,
        letterSpacing = (-0.25).sp
    ),
    displaySmall = TextStyle(
        fontFamily = CinzelDecorativeFont,
        fontWeight = FontWeight.Bold,
        fontSize = 36.sp,
        lineHeight = 44.sp
    ),

    // Headlines - Section titles (e.g., "國會風雲") - Use Noto Serif SC for Chinese
    headlineLarge = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 32.sp,
        lineHeight = 40.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 28.sp,
        lineHeight = 36.sp
    ),
    headlineSmall = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 32.sp
    ),

    // Titles - Card titles, screen headers - Use Noto Serif SC
    titleLarge = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 28.sp
    ),
    titleMedium = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.15.sp
    ),
    titleSmall = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.1.sp
    ),

    // Body - Main content text - Use Noto Serif SC for Chinese content
    bodyLarge = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 24.sp,
        letterSpacing = 0.5.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 0.25.sp
    ),
    bodySmall = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.4.sp
    ),

    // Labels - Buttons, chips, small labels - Use Bodoni Moda for numbers/timers
    labelLarge = TextStyle(
        fontFamily = SansFont,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp,
        letterSpacing = 1.sp
    ),
    labelMedium = TextStyle(
        fontFamily = SansFont,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.5.sp
    ),
    labelSmall = TextStyle(
        fontFamily = SansFont,
        fontWeight = FontWeight.Medium,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        letterSpacing = 2.sp
    )
)

// Additional Typography Styles for specific use cases
object ParliamentTypography {
    // For English titles with decorative style
    val englishTitle = TextStyle(
        fontFamily = CinzelDecorativeFont,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp,
        letterSpacing = 2.sp
    )

    // For timer/numbers display
    val timerDisplay = TextStyle(
        fontFamily = BodoniModaFont,
        fontWeight = FontWeight.Bold,
        fontSize = 48.sp,
        letterSpacing = 1.sp
    )

    // For Chinese quotes
    val chineseQuote = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 26.sp
    )

    // For role names
    val roleName = TextStyle(
        fontFamily = NotoSerifSCFont,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp
    )

    // For English subtitles
    val englishSubtitle = TextStyle(
        fontFamily = CinzelDecorativeFont,
        fontWeight = FontWeight.Bold,
        fontSize = 12.sp,
        letterSpacing = 3.sp
    )
}
