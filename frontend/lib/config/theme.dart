import 'package:flutter/material.dart';

/// 應用程式主題配置
class AppTheme {
  // 主要顏色 - 1812 年代復古風格
  static const Color primaryColor = Color(0xFF8B4513); // 深棕色
  static const Color secondaryColor = Color(0xFFD4AF37); // 金色
  static const Color accentColor = Color(0xFF2F4F4F); // 深灰綠

  // 角色陣營顏色
  static const Color workerColor = Color(0xFF4A6741); // 工人 - 深綠
  static const Color factoryColor = Color(0xFF8B4513); // 工廠主 - 棕色
  static const Color ludditeColor = Color(0xFF8B0000); // 盧德派 - 深紅
  static const Color reformerColor = Color(0xFF4169E1); // 改革者 - 皇家藍
  static const Color mpColor = Color(0xFF483D8B); // 議員 - 深紫

  // 背景色
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color cardBackground = Color(0xFF16213E);

  // 亮色主題
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'NotoSansTC',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  // 暗色主題 - 主要使用
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: secondaryColor,
      secondary: primaryColor,
      surface: cardBackground,
      background: darkBackground,
    ),
    fontFamily: 'NotoSansTC',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardTheme: CardTheme(
      color: cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: darkBackground,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
    ),
  );

  // 根據角色類型取得顏色
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
        return primaryColor;
    }
  }
}
