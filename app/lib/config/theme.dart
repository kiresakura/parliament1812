import 'package:flutter/material.dart';

class Parliament1812Theme {
  // 1812 年代顏色
  static const Color _darkRed = Color(0xFF8B0000);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _darkGold = Color(0xFFB8941C);
  static const Color _cream = Color(0xFFFFF8DC);
  static const Color _darkBrown = Color(0xFF3C1810);
  static const Color _lightBrown = Color(0xFF8B4513);
  static const Color _charcoal = Color(0xFF2F2F2F);
  static const Color _slate = Color(0xFF1A1A1A);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    
    // 主色調
    primarySwatch: Colors.red,
    
    colorScheme: const ColorScheme.dark(
      primary: _darkRed,
      primaryContainer: Color(0xFF660000),
      secondary: _gold,
      secondaryContainer: _darkGold,
      surface: _slate,
      surfaceContainer: _charcoal,
      onPrimary: _cream,
      onSecondary: _darkBrown,
      onSurface: _cream,
      error: Color(0xFFFF6B6B),
      outline: _lightBrown,
    ),

    // 背景
    scaffoldBackgroundColor: _slate,
    
    // 卡片主題
    cardTheme: CardThemeData(
      color: _charcoal,
      shadowColor: _darkRed.withValues(alpha: 0.3),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _lightBrown.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    ),

    // 應用欄主題
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkRed,
      foregroundColor: _cream,
      elevation: 4,
      titleTextStyle: TextStyle(
        color: _cream,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'serif',
      ),
    ),

    // 按鈕主題
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkRed,
        foregroundColor: _cream,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'serif',
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _gold,
        side: const BorderSide(color: _gold, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'serif',
        ),
      ),
    ),

    // 文字主題
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: _cream,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        fontFamily: 'serif',
      ),
      displayMedium: TextStyle(
        color: _cream,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFamily: 'serif',
      ),
      headlineLarge: TextStyle(
        color: _cream,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'serif',
      ),
      headlineMedium: TextStyle(
        color: _cream,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontFamily: 'serif',
      ),
      titleLarge: TextStyle(
        color: _cream,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'serif',
      ),
      titleMedium: TextStyle(
        color: _cream,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'serif',
      ),
      bodyLarge: TextStyle(
        color: _cream,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        fontFamily: 'serif',
      ),
      bodyMedium: TextStyle(
        color: _cream,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'serif',
      ),
      labelLarge: TextStyle(
        color: _gold,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'serif',
      ),
    ),

    // 輸入欄主題
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _charcoal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _lightBrown),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _lightBrown.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _gold, width: 2),
      ),
      labelStyle: const TextStyle(color: _gold),
      hintStyle: TextStyle(color: _cream.withOpacity(0.6)),
    ),

    // 圖標主題
    iconTheme: const IconThemeData(
      color: _gold,
      size: 24,
    ),

    // Dialog 主題
    dialogTheme: DialogThemeData(
      backgroundColor: _charcoal,
      titleTextStyle: const TextStyle(
        color: _cream,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'serif',
      ),
      contentTextStyle: const TextStyle(
        color: _cream,
        fontSize: 16,
        fontFamily: 'serif',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _lightBrown.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    ),

    // 分割線主題
    dividerTheme: DividerThemeData(
      color: _lightBrown.withValues(alpha: 0.3),
      thickness: 1,
      space: 1,
    ),
  );

  // 遊戲專用顏色
  static const Color reputationColor = Color(0xFFFF6B6B);  // 聲望（紅色）
  static const Color influenceColor = Color(0xFF4ECDC4);   // 影響力（青色）
  static const Color goldColor = _gold;                    // 金幣
  
  // 卡牌稀有度顏色
  static const Color commonCardColor = Color(0xFF9E9E9E);     // 普通（灰）
  static const Color rareCardColor = Color(0xFF2196F3);       // 稀有（藍）
  static const Color epicCardColor = Color(0xFF9C27B0);       // 史詩（紫）
  static const Color legendaryCardColor = Color(0xFFFFD700);  // 傳說（金）
  
  // 陣營顏色
  static const Color laborColor = Color(0xFFE53935);      // 勞工派（紅）
  static const Color capitalColor = Color(0xFF43A047);    // 資方派（綠）
  static const Color reformColor = Color(0xFF1E88E5);     // 改革派（藍）
  static const Color neutralColor = Color(0xFF757575);    // 中立（灰）

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