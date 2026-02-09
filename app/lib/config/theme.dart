import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Parliament1812Theme {
  // 1812 年代顏色
  static const Color darkRed = Color(0xFF8B0000);
  static const Color gold = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8941C);
  static const Color cream = Color(0xFFFFF8DC);
  static const Color darkBrown = Color(0xFF3C1810);
  static const Color lightBrown = Color(0xFF8B4513);
  static const Color charcoal = Color(0xFF2F2F2F);
  static const Color slate = Color(0xFF1A1A1A);

  /// Base serif text style using Playfair Display
  static TextStyle get _serifBase => GoogleFonts.playfairDisplay();

  /// Body serif using Merriweather for readability
  static TextStyle get _bodySerifBase => GoogleFonts.merriweather();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,

      // 主色調
      primarySwatch: Colors.red,

      colorScheme: const ColorScheme.dark(
        primary: darkRed,
        primaryContainer: Color(0xFF660000),
        secondary: gold,
        secondaryContainer: darkGold,
        surface: slate,
        surfaceContainer: charcoal,
        onPrimary: cream,
        onSecondary: darkBrown,
        onSurface: cream,
        error: Color(0xFFFF6B6B),
        outline: lightBrown,
      ),

      // 背景
      scaffoldBackgroundColor: slate,

      // 卡片主題
      cardTheme: CardThemeData(
        color: charcoal,
        shadowColor: darkRed.withValues(alpha: 0.3),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: lightBrown.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      // 應用欄主題
      appBarTheme: AppBarTheme(
        backgroundColor: darkRed,
        foregroundColor: cream,
        elevation: 4,
        titleTextStyle: _serifBase.copyWith(
          color: cream,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkRed,
          foregroundColor: cream,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: _serifBase.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          textStyle: _serifBase.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 文字主題 — display/headline use Playfair, body uses Merriweather
      textTheme: TextTheme(
        displayLarge: _serifBase.copyWith(
          color: cream,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: _serifBase.copyWith(
          color: cream,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: _serifBase.copyWith(
          color: cream,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: _serifBase.copyWith(
          color: cream,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: _serifBase.copyWith(
          color: cream,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: _bodySerifBase.copyWith(
          color: gold,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: _bodySerifBase.copyWith(
          color: gold,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: _bodySerifBase.copyWith(
          color: gold,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 輸入欄主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: charcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBrown),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightBrown.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
        labelStyle: _bodySerifBase.copyWith(color: gold),
        hintStyle: _bodySerifBase.copyWith(
            color: cream.withValues(alpha: 0.6)),
      ),

      // 圖標主題
      iconTheme: const IconThemeData(
        color: gold,
        size: 24,
      ),

      // Dialog 主題
      dialogTheme: DialogThemeData(
        backgroundColor: charcoal,
        titleTextStyle: _serifBase.copyWith(
          color: cream,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: _bodySerifBase.copyWith(
          color: cream,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: lightBrown.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),

      // SnackBar 主題
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoal,
        contentTextStyle: _bodySerifBase.copyWith(color: cream),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: gold.withValues(alpha: 0.3)),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip 主題
      chipTheme: ChipThemeData(
        backgroundColor: charcoal,
        labelStyle: _bodySerifBase.copyWith(color: cream, fontSize: 12),
        side: BorderSide(color: lightBrown.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // BottomSheet 主題
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // PopupMenu 主題
      popupMenuTheme: PopupMenuThemeData(
        color: charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: lightBrown.withValues(alpha: 0.3)),
        ),
      ),

      // Switch 主題
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return lightBrown;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return gold.withValues(alpha: 0.3);
          }
          return lightBrown.withValues(alpha: 0.2);
        }),
      ),

      // 分割線主題
      dividerTheme: DividerThemeData(
        color: lightBrown.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),

      // Dropdown 主題
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: charcoal,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightBrown.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  // 遊戲專用顏色
  static const Color reputationColor = Color(0xFFFF6B6B); // 聲望（紅色）
  static const Color influenceColor = Color(0xFF4ECDC4); // 影響力（青色）
  static const Color goldColor = gold; // 金幣

  // 卡牌稀有度顏色
  static const Color commonCardColor = Color(0xFF9E9E9E); // 普通（灰）
  static const Color rareCardColor = Color(0xFF2196F3); // 稀有（藍）
  static const Color epicCardColor = Color(0xFF9C27B0); // 史詩（紫）
  static const Color legendaryCardColor = Color(0xFFFFD700); // 傳說（金）

  // 陣營顏色
  static const Color laborColor = Color(0xFFE53935); // 勞工派（紅）
  static const Color capitalColor = Color(0xFF43A047); // 資方派（綠）
  static const Color reformColor = Color(0xFF1E88E5); // 改革派（藍）
  static const Color neutralColor = Color(0xFF757575); // 中立（灰）

  // 聲望變化顏色
  static const Color reputationUpColor = Color(0xFF4CAF50); // 綠
  static const Color reputationDownColor = Color(0xFFF44336); // 紅

  // 實用方法：獲取稀有度顏色
  static Color getCardRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'n':
      case 'normal':
      case 'common':
        return commonCardColor;
      case 'r':
      case 'rare':
        return rareCardColor;
      case 'sr':
      case 'epic':
        return epicCardColor;
      case 'ssr':
      case 'legendary':
        return legendaryCardColor;
      default:
        return commonCardColor;
    }
  }

  // 實用方法：獲取陣營顏色
  static Color getFactionColor(String faction) {
    switch (faction.toLowerCase()) {
      case 'labor':
      case 'worker':
      case '勞工派':
        return laborColor;
      case 'capital':
      case 'factory':
      case '資方派':
        return capitalColor;
      case 'reform':
      case '改革派':
        return reformColor;
      case 'neutral':
      case '中立派':
        return neutralColor;
      default:
        return neutralColor;
    }
  }
}
