import 'package:flutter/material.dart';

// 重新匯出新的 Design System 色彩
// ignore: unused_import
import '../ui/theme/game_colors.dart' as design_system;

/// 遊戲專用顏色常數 — 已升級至羅塞蒂配色系統 v1.0
///
/// ⚠️ 此檔案保留向後相容。新程式碼請直接使用：
/// `import 'package:parliament1812/ui/theme/game_colors.dart';`
class GameColors {
  GameColors._();

  // ═══ 金色系統（升級至維多利亞金）═══
  static const Color gold = design_system.GameColors.victorianGold;
  static const Color goldLight = design_system.GameColors.goldLight;
  static const Color goldDark = design_system.GameColors.goldDim;

  // ═══ 選中狀態金色呼吸光暈 ═══
  static const Color selectionGlow = design_system.GameColors.victorianGold;
  static const double selectionGlowBlur = 12.0;
  static const double selectionGlowOpacityMin = 0.4;
  static const double selectionGlowOpacityMax = 0.8;
  static const double selectionBorderWidth = 1.5;

  // ═══ 按鈕色（升級至深紫系）═══
  static const Color btnGradientStart = design_system.GameColors.bgPrimary;
  static const Color btnGradientEnd = design_system.GameColors.bgSecondary;
  static const Color btnBorder = design_system.GameColors.victorianGold;
  static const Color btnText = design_system.GameColors.textPrimary;

  // 行動按鈕輔助色（羅塞蒂 v2 鮮明配色）
  static const Color btnChallenge = Color(0xFF3D7CC9);   // 質詢藍
  static const Color btnAlliance = Color(0xFF27AE60);    // 結盟綠
  static const Color btnDraw = Color(0xFF6B3FA0);        // 抽牌紫
  static const Color btnEndTurn = Color(0xFFC21E56);     // 結束回合玫瑰紅
  static const Color btnInvestigate = Color(0xFF3D7CC9); // 調查藍
  static const Color btnNextPhase = Color(0xFFC21E56);   // 下一階段玫瑰紅

  // 投票按鈕輔助色
  static const Color btnVoteFor = Color(0xFF27AE60);     // 支持綠
  static const Color btnVoteAgainst = Color(0xFFC21E56); // 反對玫瑰紅
  static const Color btnAbstain = Color(0xFF6B6B6B);     // 棄權灰
  static const Color btnWaiting = Color(0xFF3A3A3A);     // 等待中灰

  // ═══ 數值飛字顏色 ═══
  static const Color flyTextPositive = design_system.GameColors.flyTextPositive;
  static const Color flyTextNegative = design_system.GameColors.flyTextNegative;

  // ═══ 事件日誌顏色 ═══
  static const Color logChallenge = design_system.GameColors.logChallenge;
  static const Color logAlliance = design_system.GameColors.logAlliance;
  static const Color logVote = design_system.GameColors.logVote;
  static const Color logCard = design_system.GameColors.logCard;
  static const Color logEconomy = design_system.GameColors.logEconomy;
  static const Color logSystem = design_system.GameColors.logSystem;

  // ═══ AI 回合指示 ═══
  static const Color aiTurnHighlight = design_system.GameColors.victorianGold;
}
