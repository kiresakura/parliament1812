import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 羅塞蒂字體規格系統 v1.0 — 15 種字體規格
///
/// 設計：羅塞蒂（美學大臣）
/// 實現：艾達（技術大臣）
///
/// 使用 Google Fonts 載入 Playfair Display（serif 標題）與
/// Merriweather（serif 內文），不依賴外部字體檔案。
/// 「rounded」設計用系統 .rounded 替代。
class GameFont {
  GameFont._();

  // ═══════════════════════════════════════════
  // 基礎字體
  // ═══════════════════════════════════════════

  /// Playfair Display — 維多利亞風格 serif 標題字體
  static TextStyle get _serif => GoogleFonts.playfairDisplay();

  /// Merriweather — serif 內文字體（較高可讀性）
  static TextStyle get _body => GoogleFonts.merriweather();

  // ═══════════════════════════════════════════
  // 標題層
  // ═══════════════════════════════════════════

  /// 遊戲主標題（LoginView 遊戲名稱）
  /// 顏色：victorianGold + 文字陰影
  static TextStyle get gameTitle => _serif.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      );

  /// 頁面標題（MainMenu 段落標題）
  /// 顏色：textPrimary
  static TextStyle get sectionTitle => _serif.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  /// 卡牌名稱
  /// 顏色：textPrimary，需陰影確保可讀性
  static TextStyle get cardTitle => _serif.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  // ═══════════════════════════════════════════
  // 副標題 / 標籤層
  // ═══════════════════════════════════════════

  /// 行動按鈕文字
  /// 顏色：依情境 textPrimary 或 textSecondary
  static TextStyle get uiLabel => _body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  /// 回合階段標籤
  /// 顏色：textGold
  static TextStyle get turnPhase => _serif.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  /// 議案標題
  /// 顏色：textGold（重要）或 textPrimary（一般）
  static TextStyle get billTitle => _serif.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  /// 議案描述
  /// 顏色：textSecondary
  static TextStyle get billBody => _serif.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.normal,
      );

  // ═══════════════════════════════════════════
  // 特殊數字顯示
  // ═══════════════════════════════════════════

  /// 回合計數器
  /// 顏色：textGold
  static TextStyle get turnCounter => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        fontFamily: '.SF Pro Rounded', // iOS rounded fallback
      );

  /// 資源數字（血量、票數等）
  /// 顏色：textPrimary
  static TextStyle get resourceNumber => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: '.SF Pro Rounded',
      );

  /// 浮動 +/- 數字
  /// 顏色：actionAlliance（正）/ roseRed（負）
  static TextStyle get floatingNumber => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        fontFamily: '.SF Pro Rounded',
      );

  /// 倒計時
  /// 顏色：goldLight
  static TextStyle get countdown => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      );

  // ═══════════════════════════════════════════
  // 按鈕文字
  // ═══════════════════════════════════════════

  /// 主要按鈕（開始對局）
  /// 顏色：bgPrimary（在金色底上用深色）
  static TextStyle get primaryButton => _serif.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  /// 次要按鈕
  /// 顏色：textSecondary
  static TextStyle get secondaryButton => _serif.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  /// 結束回合按鈕
  /// 顏色：bgPrimary
  static TextStyle get endTurnButton => _serif.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      );

  /// 登入按鈕
  /// 顏色：textPrimary
  static TextStyle get loginButton => _body.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  // ═══════════════════════════════════════════
  // 日誌 / 小字
  // ═══════════════════════════════════════════

  /// 事件日誌
  /// 顏色：依重要度對應
  static TextStyle get eventLog => _serif.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  /// 連勝數字
  /// 顏色：roseLight
  static TextStyle get winStreak => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        fontFamily: '.SF Pro Rounded',
      );

  /// 任務文字
  /// 顏色：textPrimary
  static TextStyle get missionText => _body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );
}
