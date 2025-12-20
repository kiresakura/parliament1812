import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 應用程式主題配置 - 1812 年英國國會風格
/// 基於 Figma 設計文件：維多利亞/攝政時期風格 + Civ6 六角形元素
class AppTheme {
  // ==================== 主要顏色 (Figma Design System) ====================
  /// 深夜藍 - 主要背景色 (模擬燭光下的國會議事廳)
  static const Color primaryBackground = Color(0xFF1A1A2E);

  /// 深海藍 - 卡片背景色
  static const Color cardBackground = Color(0xFF16213E);

  /// 深棕背景 - 替代背景色
  static const Color darkBrownBackground = Color(0xFF1A1614);

  /// 面板深棕 - 面板背景
  static const Color panelBackground = Color(0xFF241B14);

  /// 古典金 - 主要強調色 (黃銅/鍍金效果)
  static const Color accentGold = Color(0xFFD4AF37);

  /// 馬鞍棕 - 次要強調色 (皮革/紅木)
  static const Color saddleBrown = Color(0xFF8B4513);

  // ==================== 文字顏色 ====================
  /// 羊皮紙奶油色 - 主要文字 (高對比)
  static const Color textPrimary = Color(0xFFF5E6D3);

  /// 淡金色 - 次要文字
  static const Color textSecondary = Color(0xFFB8A07E);

  /// 暗金色 - 第三層文字
  static const Color textTertiary = Color(0xFF8B7753);

  /// 墨水色 - 羊皮紙上的文字
  static const Color inkColor = Color(0xFF2C1810);

  // ==================== 政黨顏色 (歷史準確) ====================
  /// 托利黨 - 皇家藍 (保守派/政府)
  static const Color toryColor = Color(0xFF1E3A5F);
  static const Color toryBlue = toryColor; // 別名

  /// 輝格黨 - 橘黃色/Buff (自由派/在野)
  static const Color whigColor = Color(0xFFCC7722);
  static const Color whigOrange = whigColor; // 別名

  /// 中立 - 棕色
  static const Color neutralColor = Color(0xFF8B7753);

  // ==================== 向後相容別名 ====================
  static const Color darkBackground = primaryBackground;
  static const Color secondaryColor = accentGold;
  static const Color primaryColor = accentGold;

  // ==================== 投票顏色 ====================
  /// 贊成 (Aye) - 國會綠 (下議院綠色長椅)
  static const Color voteAye = Color(0xFF2D5A27);

  /// 反對 (Nay) - 深緋紅
  static const Color voteNay = Color(0xFF8B2500);

  /// 棄權 - 灰色
  static const Color voteAbstain = Color(0xFF5A5A5A);

  // ==================== 角色陣營顏色 ====================
  static const Color workerColor = Color(0xFF4A6741);   // 工人 - 深綠
  static const Color factoryColor = Color(0xFF8B4513); // 工廠主 - 棕色
  static const Color ludditeColor = Color(0xFF8B0000); // 盧德派 - 深紅
  static const Color reformerColor = Color(0xFF4169E1); // 改革者 - 皇家藍
  static const Color mpColor = Color(0xFF483D8B);       // 議員 - 深紫

  // ==================== 狀態顏色 ====================
  static const Color successColor = Color(0xFF2D5A27);
  static const Color errorColor = Color(0xFF8B2500);
  static const Color warningColor = Color(0xFFCC7722);
  static const Color infoColor = Color(0xFF1E3A5F);

  // ==================== 歷史感特效顏色 ====================
  static const Color parchmentColor = Color(0xFFF5E6C8);
  static const Color parchmentDark = Color(0xFFD4C4A8);
  static const Color waxSealColor = Color(0xFFB22222);
  static const Color candleGlow = Color(0xFFFFD700);
  static const Color brassColor = Color(0xFFB5A642);
  static const Color copperColor = Color(0xFFB87333);
  static const Color ironColor = Color(0xFF434B4D);

  // ==================== 漸層色 ====================
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
  );

  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
  );

  static const LinearGradient parchmentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5E6C8), Color(0xFFE8D5B0), Color(0xFFF5E6C8)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F1A)],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF241B14), Color(0xFF1A1614)],
  );

  static const RadialGradient vignetteGradient = RadialGradient(
    colors: [Colors.transparent, Colors.transparent, Color(0xCC1A1614)],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient candleGlowGradient = RadialGradient(
    colors: [Color(0x40FFD700), Color(0x20FFD700), Colors.transparent],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== 字體樣式 (Georgian 時期風格) ====================
  // 英文標題字體 - Cinzel (古典羅馬風格，類似 Georgia)
  static TextStyle get displayLarge => GoogleFonts.cinzel(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: accentGold,
        letterSpacing: 8,
        shadows: [
          Shadow(
            color: accentGold.withValues(alpha: 0.4),
            blurRadius: 30,
          ),
          const Shadow(
            color: Colors.black,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      );

  static TextStyle get displayMedium => GoogleFonts.cinzel(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 4,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle get displaySmall => GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 2,
      );

  // 中文標題字體 - Noto Serif TC (思源宋體/明體)
  static TextStyle get headlineLarge => GoogleFonts.notoSerifTc(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textSecondary,
        letterSpacing: 8,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle get headlineMedium => GoogleFonts.notoSerifTc(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.notoSerifTc(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  // 中文內文字體
  static TextStyle get bodyLarge => GoogleFonts.notoSerifTc(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.notoSerifTc(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.notoSerifTc(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textTertiary,
        height: 1.4,
      );

  // 標籤字體
  static TextStyle get labelLarge => GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: accentGold,
        letterSpacing: 2,
      );

  static TextStyle get labelMedium => GoogleFonts.notoSerifTc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 1,
      );

  static TextStyle get labelSmall => GoogleFonts.cinzel(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 3,
      );

  // 羊皮紙風格文字
  static TextStyle get parchmentText => GoogleFonts.notoSerifTc(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: inkColor,
        height: 1.8,
      );

  // 引用文字
  static TextStyle get quoteText => GoogleFonts.notoSerifTc(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: textSecondary,
        height: 1.6,
      );

  // ==================== 陰影效果 ====================
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get goldGlowShadow => [
        BoxShadow(
          color: accentGold.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get waxSealShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: const Offset(2, 2),
        ),
      ];

  // ==================== 邊框裝飾 ====================
  static BoxDecoration get parchmentDecoration => BoxDecoration(
        gradient: parchmentGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: saddleBrown.withValues(alpha: 0.5), width: 2),
        boxShadow: cardShadow,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold.withValues(alpha: 0.3), width: 1),
        boxShadow: cardShadow,
      );

  static BoxDecoration get panelDecoration => BoxDecoration(
        color: panelBackground.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: accentGold.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get goldenFrameDecoration => BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold, width: 2),
        boxShadow: [
          ...cardShadow,
          BoxShadow(
            color: accentGold.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      );

  /// 六角形切角裝飾 (Civ6 風格)
  static BoxDecoration get hexagonalDecoration => BoxDecoration(
        color: panelBackground.withValues(alpha: 0.8),
        border: Border.all(color: accentGold, width: 2),
        boxShadow: cardShadow,
      );

  // ==================== 主題配置 ====================
  /// Light theme (用於特定場景，如羊皮紙背景)
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: parchmentColor,
        colorScheme: const ColorScheme.light(
          primary: saddleBrown,
          secondary: accentGold,
          surface: parchmentColor,
          onPrimary: parchmentColor,
          onSecondary: inkColor,
          onSurface: inkColor,
          error: errorColor,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: saddleBrown,
          titleTextStyle: headlineMedium.copyWith(color: parchmentColor),
          iconTheme: const IconThemeData(color: parchmentColor),
        ),
        textTheme: TextTheme(
          displayLarge: displayLarge.copyWith(color: inkColor),
          displayMedium: displayMedium.copyWith(color: inkColor),
          displaySmall: displaySmall.copyWith(color: inkColor),
          headlineLarge: headlineLarge.copyWith(color: inkColor),
          headlineMedium: headlineMedium.copyWith(color: inkColor),
          headlineSmall: headlineSmall.copyWith(color: inkColor),
          bodyLarge: bodyLarge.copyWith(color: inkColor),
          bodyMedium: bodyMedium.copyWith(color: inkColor),
          bodySmall: bodySmall.copyWith(color: inkColor),
          labelLarge: labelLarge.copyWith(color: saddleBrown),
          labelMedium: labelMedium.copyWith(color: inkColor),
          labelSmall: labelSmall.copyWith(color: saddleBrown),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryBackground,
        colorScheme: const ColorScheme.dark(
          primary: accentGold,
          secondary: saddleBrown,
          surface: cardBackground,
          onPrimary: primaryBackground,
          onSecondary: textPrimary,
          onSurface: textPrimary,
          error: errorColor,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: headlineMedium,
          iconTheme: const IconThemeData(color: accentGold),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accentGold.withValues(alpha: 0.3)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: primaryBackground,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 6,
            shadowColor: accentGold.withValues(alpha: 0.4),
            textStyle: GoogleFonts.notoSerifTc(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentGold,
            side: const BorderSide(color: accentGold, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.notoSerifTc(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentGold,
            textStyle: GoogleFonts.notoSerifTc(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panelBackground.withValues(alpha: 0.8),
          labelStyle: labelMedium,
          hintStyle: bodySmall.copyWith(color: textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: accentGold, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: accentGold, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: const BorderSide(color: accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentGold.withValues(alpha: 0.5)),
          ),
          titleTextStyle: headlineMedium,
          contentTextStyle: bodyMedium,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: panelBackground,
          contentTextStyle: bodyMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: accentGold.withValues(alpha: 0.3),
          thickness: 1,
        ),
        iconTheme: const IconThemeData(
          color: accentGold,
          size: 24,
        ),
        textTheme: TextTheme(
          displayLarge: displayLarge,
          displayMedium: displayMedium,
          displaySmall: displaySmall,
          headlineLarge: headlineLarge,
          headlineMedium: headlineMedium,
          headlineSmall: headlineSmall,
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelLarge: labelLarge,
          labelMedium: labelMedium,
          labelSmall: labelSmall,
        ),
      );

  // ==================== 工具方法 ====================
  /// 根據政黨取得顏色
  static Color getPartyColor(String party) {
    switch (party.toLowerCase()) {
      case 'tory':
        return toryColor;
      case 'whig':
        return whigColor;
      case 'neutral':
        return neutralColor;
      default:
        return neutralColor;
    }
  }

  /// 根據角色類型取得顏色
  static Color getRoleColor(String roleType) {
    switch (roleType) {
      case 'worker':
        return workerColor;
      case 'factory':
        return factoryColor;
      case 'luddite':
        return ludditeColor;
      case 'reformer':
        return reformerColor;
      case 'mp':
        return mpColor;
      default:
        return neutralColor;
    }
  }

  /// 根據角色類型取得漸層
  static LinearGradient getRoleGradient(String roleType) {
    final color = getRoleColor(roleType);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.9),
      ],
    );
  }

  /// 根據角色類型取得邊框裝飾
  static BoxDecoration getRoleCardDecoration(String roleType) {
    final color = getRoleColor(roleType);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          cardBackground,
          color.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 15,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 獲取角色圖示
  static IconData getRoleIcon(String roleType) {
    switch (roleType) {
      case 'worker':
        return Icons.engineering;
      case 'factory':
        return Icons.factory;
      case 'luddite':
        return Icons.whatshot;
      case 'reformer':
        return Icons.balance;
      case 'mp':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }

  /// 投票按鈕裝飾
  static BoxDecoration getVoteButtonDecoration(String voteType, {bool selected = false}) {
    Color color;
    switch (voteType.toLowerCase()) {
      case 'aye':
        color = voteAye;
        break;
      case 'nay':
        color = voteNay;
        break;
      default:
        color = voteAbstain;
    }

    return BoxDecoration(
      color: selected ? color : Colors.transparent,
      border: Border.all(color: color, width: 2),
      borderRadius: BorderRadius.circular(8),
      boxShadow: selected
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ]
          : null,
    );
  }
}

/// 高對比模式顏色配置
class HighContrastColors {
  // ==================== 高對比背景色 ====================
  /// 純黑背景 - 最高對比度
  static const Color primaryBackground = Color(0xFF000000);

  /// 深灰卡片背景
  static const Color cardBackground = Color(0xFF121212);

  /// 面板背景
  static const Color panelBackground = Color(0xFF1A1A1A);

  // ==================== 高對比強調色 ====================
  /// 明亮金色 - 更高飽和度
  static const Color accentGold = Color(0xFFFFD700);

  /// 亮橙色 - 警示用
  static const Color accentOrange = Color(0xFFFF8C00);

  // ==================== 高對比文字色 ====================
  /// 純白 - 主要文字
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// 亮黃 - 次要文字
  static const Color textSecondary = Color(0xFFFFEB3B);

  /// 淺灰 - 第三層文字
  static const Color textTertiary = Color(0xFFBDBDBD);

  // ==================== 高對比狀態色 ====================
  /// 成功綠 - 更明亮
  static const Color successColor = Color(0xFF4CAF50);

  /// 錯誤紅 - 更明亮
  static const Color errorColor = Color(0xFFFF5252);

  /// 警告黃
  static const Color warningColor = Color(0xFFFFEB3B);

  /// 資訊藍
  static const Color infoColor = Color(0xFF2196F3);

  // ==================== 高對比投票色 ====================
  /// 贊成綠
  static const Color voteAye = Color(0xFF4CAF50);

  /// 反對紅
  static const Color voteNay = Color(0xFFFF5252);

  /// 棄權灰
  static const Color voteAbstain = Color(0xFF9E9E9E);

  // ==================== 高對比政黨色 ====================
  static const Color toryColor = Color(0xFF2196F3);  // 更亮的藍
  static const Color whigColor = Color(0xFFFF9800);  // 更亮的橙
  static const Color neutralColor = Color(0xFF9E9E9E);

  // ==================== 高對比角色色 ====================
  static const Color workerColor = Color(0xFF4CAF50);   // 工人 - 亮綠
  static const Color factoryColor = Color(0xFFFF9800); // 工廠主 - 橙色
  static const Color ludditeColor = Color(0xFFFF5252); // 盧德派 - 亮紅
  static const Color reformerColor = Color(0xFF2196F3); // 改革者 - 亮藍
  static const Color mpColor = Color(0xFF9C27B0);       // 議員 - 亮紫
}

/// 無障礙主題設定
class AccessibilitySettings {
  static double fontScale = 1.0;
  static bool highContrast = false;
  static bool reduceMotion = false;
  static bool largeText = false;

  /// 最小字體大小 (考慮視力障礙)
  static const double minFontSize = 12.0;

  /// 最小觸控區域 (iOS HIG 建議)
  static const double minTouchTarget = 44.0;

  static TextStyle scaleText(TextStyle style) {
    double fontSize = (style.fontSize ?? 16) * fontScale;
    if (largeText) {
      fontSize *= 1.3;
    }
    return style.copyWith(
      fontSize: fontSize.clamp(minFontSize, 48.0),
    );
  }

  /// 取得適應無障礙設定的顏色
  static Color adaptiveColor(Color normalColor, Color highContrastColor) {
    return highContrast ? highContrastColor : normalColor;
  }

  /// 取得背景色
  static Color get backgroundColor => adaptiveColor(
    AppTheme.primaryBackground,
    HighContrastColors.primaryBackground,
  );

  /// 取得卡片背景色
  static Color get cardBackgroundColor => adaptiveColor(
    AppTheme.cardBackground,
    HighContrastColors.cardBackground,
  );

  /// 取得強調色
  static Color get accentColor => adaptiveColor(
    AppTheme.accentGold,
    HighContrastColors.accentGold,
  );

  /// 取得主要文字色
  static Color get textPrimaryColor => adaptiveColor(
    AppTheme.textPrimary,
    HighContrastColors.textPrimary,
  );

  /// 取得次要文字色
  static Color get textSecondaryColor => adaptiveColor(
    AppTheme.textSecondary,
    HighContrastColors.textSecondary,
  );

  /// 取得成功色
  static Color get successColor => adaptiveColor(
    AppTheme.successColor,
    HighContrastColors.successColor,
  );

  /// 取得錯誤色
  static Color get errorColor => adaptiveColor(
    AppTheme.errorColor,
    HighContrastColors.errorColor,
  );

  /// 取得投票贊成色
  static Color get voteAyeColor => adaptiveColor(
    AppTheme.voteAye,
    HighContrastColors.voteAye,
  );

  /// 取得投票反對色
  static Color get voteNayColor => adaptiveColor(
    AppTheme.voteNay,
    HighContrastColors.voteNay,
  );

  /// 取得動畫時長 (考慮減少動態效果)
  static Duration animationDuration(Duration normal) {
    if (reduceMotion) {
      return Duration.zero;
    }
    return normal;
  }

  /// 取得動畫曲線 (考慮減少動態效果)
  static Curve animationCurve(Curve normal) {
    if (reduceMotion) {
      return Curves.linear;
    }
    return normal;
  }

  /// 根據角色類型取得適應顏色
  static Color getRoleColor(String roleType) {
    if (!highContrast) {
      return AppTheme.getRoleColor(roleType);
    }
    switch (roleType) {
      case 'worker':
        return HighContrastColors.workerColor;
      case 'factory':
        return HighContrastColors.factoryColor;
      case 'luddite':
        return HighContrastColors.ludditeColor;
      case 'reformer':
        return HighContrastColors.reformerColor;
      case 'mp':
        return HighContrastColors.mpColor;
      default:
        return HighContrastColors.neutralColor;
    }
  }

  /// 取得政黨顏色
  static Color getPartyColor(String party) {
    if (!highContrast) {
      return AppTheme.getPartyColor(party);
    }
    switch (party.toLowerCase()) {
      case 'tory':
        return HighContrastColors.toryColor;
      case 'whig':
        return HighContrastColors.whigColor;
      default:
        return HighContrastColors.neutralColor;
    }
  }
}
