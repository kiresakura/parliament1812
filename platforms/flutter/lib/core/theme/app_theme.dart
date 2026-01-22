import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 1812 國會風雲 - 維多利亞風格主題
class AppTheme {
  AppTheme._();

  // ===== 顏色定義 =====
  static const Color primaryDark = Color(0xFF1A1A2E);    // 深藍黑
  static const Color primaryMid = Color(0xFF16213E);     // 中藍
  static const Color accent = Color(0xFFD4AF37);         // 金色
  static const Color accentLight = Color(0xFFE8C874);    // 淺金色
  static const Color textPrimary = Color(0xFFE8E8E8);    // 淺灰
  static const Color textSecondary = Color(0xFFA0A0A0);  // 中灰
  static const Color danger = Color(0xFFE74C3C);         // 紅色
  static const Color success = Color(0xFF27AE60);        // 綠色
  static const Color warning = Color(0xFFF39C12);        // 警告橙

  // ===== 陣營顏色 =====
  static const Color workerColor = Color(0xFF8B4513);    // 工人派 - 棕色
  static const Color factoryColor = Color(0xFF4A4A4A);   // 資方派 - 灰色
  static const Color pressColor = Color(0xFF2E86AB);     // 記者 - 藍色
  static const Color ludditeColor = Color(0xFFB22222);   // 盧德派 - 暗紅

  // ===== 主題資料 =====
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: primaryMid,
        error: danger,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      // 文字主題
      textTheme: TextTheme(
        // 大標題 - Cinzel 裝飾字體
        displayLarge: GoogleFonts.cinzelDecorative(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: accent,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.cinzelDecorative(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
        displaySmall: GoogleFonts.cinzel(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // 標題 - Cinzel
        headlineLarge: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),

        // 內文 - Lora
        bodyLarge: GoogleFonts.lora(
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.lora(
          fontSize: 14,
          color: textPrimary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.lora(
          fontSize: 12,
          color: textSecondary,
          height: 1.3,
        ),

        // 標籤
        labelLarge: GoogleFonts.cinzel(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1,
        ),
        labelMedium: GoogleFonts.lora(
          fontSize: 12,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.lora(
          fontSize: 10,
          color: textSecondary,
        ),
      ),

      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cinzel(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),

      // 輸入框主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent.withAlpha(128), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: GoogleFonts.lora(color: textSecondary),
        hintStyle: GoogleFonts.lora(color: textSecondary.withAlpha(153)),
      ),

      // 卡片主題
      cardTheme: CardThemeData(
        color: primaryMid,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withAlpha(77), width: 1),
        ),
      ),

      // AppBar 主題
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: accent.withAlpha(77),
        thickness: 1,
      ),
    );
  }
}

/// 維多利亞風格裝飾
class VictorianDecorations {
  VictorianDecorations._();

  /// 金色邊框裝飾
  static BoxDecoration get goldBorder => BoxDecoration(
    border: Border.all(color: AppTheme.accent, width: 2),
    borderRadius: BorderRadius.circular(12),
  );

  /// 卡片背景裝飾
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppTheme.primaryMid,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.accent.withAlpha(128), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(77),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// 主按鈕裝飾
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppTheme.accent, AppTheme.accentLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: AppTheme.accent.withAlpha(102),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
