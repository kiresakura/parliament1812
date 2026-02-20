import 'package:flutter/material.dart';

/// 羅塞蒂配色系統 v1.0 — 深紫×維多利亞金×玫瑰紅
///
/// 設計：羅塞蒂（美學大臣）
/// 實現：艾達（技術大臣）
///
/// 三色關係：
/// - 深紫 (#1A0F2E)：背景底色，象徵議會暗室的神秘與陰謀
/// - 維多利亞金 (#D4AF37)：主調強調色，權力與榮耀
/// - 玫瑰紅 (#C21E56)：行動色，攻擊性操作、危機事件
class GameColors {
  GameColors._();

  // ═══════════════════════════════════════════
  // 背景層次
  // ═══════════════════════════════════════════
  /// 深紫主背景
  static const Color bgPrimary = Color(0xFF1A0F2E);

  /// 次級背景（卡牌背面、面板）
  static const Color bgSecondary = Color(0xFF251640);

  /// 卡牌底色
  static const Color bgCard = Color(0xFF2D1B55);

  /// 遮罩背景（85% 不透明度）
  static const Color bgOverlay = Color(0xD90D0820); // 0xD9 ≈ 0.85 * 255

  // ═══════════════════════════════════════════
  // 主色調
  // ═══════════════════════════════════════════
  /// 維多利亞金（主強調色）— 權力與榮耀
  static const Color victorianGold = Color(0xFFD4AF37);

  /// 金色高光
  static const Color goldLight = Color(0xFFF0D060);

  /// 金色陰影
  static const Color goldDim = Color(0xFF8B7320);

  /// 玫瑰紅（行動色）— 攻擊性操作、危機事件
  static const Color roseRed = Color(0xFFC21E56);

  /// 玫瑰紅高光
  static const Color roseLight = Color(0xFFE8386B);

  /// 深血紅（危機狀態）
  static const Color deepCrimson = Color(0xFF8B0000);

  // ═══════════════════════════════════════════
  // 稀有度色系
  // ═══════════════════════════════════════════
  /// N 普通：銀灰
  static const Color rarityN = Color(0xFF9E9E9E);

  /// R 稀有：天藍
  static const Color rarityR = Color(0xFF4FC3F7);

  /// SR 超稀有：薰衣草紫
  static const Color raritySR = Color(0xFFCE93D8);

  /// SSR 最高：維多利亞金
  static const Color raritySSR = Color(0xFFD4AF37);

  /// SSR 光暈色
  static const Color raritySSRGlow = Color(0xFFFFE566);

  // ═══════════════════════════════════════════
  // 功能色（行動按鈕）
  // ═══════════════════════════════════════════
  /// 質詢：冷藍
  static const Color actionQuery = Color(0xFF4FC3F7);

  /// 結盟：翠綠
  static const Color actionAlliance = Color(0xFF81C784);

  /// 抽牌：琥珀橙
  static const Color actionDraw = Color(0xFFFFB74D);

  /// 結束回合：儀式金
  static const Color actionEndTurn = Color(0xFFD4AF37);

  // ═══════════════════════════════════════════
  // 文字色
  // ═══════════════════════════════════════════
  /// 羊皮紙白（主文字）
  static const Color textPrimary = Color(0xFFF5E6C8);

  /// 次要文字
  static const Color textSecondary = Color(0xFFB8A882);

  /// 靜默文字
  static const Color textMuted = Color(0xFF7A6B5A);

  /// 金色標題
  static const Color textGold = Color(0xFFD4AF37);

  // ═══════════════════════════════════════════
  // 段位色
  // ═══════════════════════════════════════════
  /// 青銅
  static const Color rankBronze = Color(0xFFCD7F32);

  /// 白銀
  static const Color rankSilver = Color(0xFFC0C0C0);

  /// 黃金
  static const Color rankGold = Color(0xFFD4AF37);

  /// 鉑金
  static const Color rankPlatinum = Color(0xFFE5E4E2);

  /// 鑽石
  static const Color rankDiamond = Color(0xFFB9F2FF);

  // ═══════════════════════════════════════════
  // 舊系統相容色（保持向後相容）
  // ═══════════════════════════════════════════
  /// @deprecated 使用 [victorianGold] 替代
  static const Color gold = victorianGold;

  /// @deprecated 使用 [goldLight] 替代
  static const Color selectionGlow = victorianGold;

  /// 數值飛字正面
  static const Color flyTextPositive = actionAlliance;

  /// 數值飛字負面
  static const Color flyTextNegative = roseRed;

  /// 事件日誌色
  static const Color logChallenge = Color(0xFFC62828);
  static const Color logAlliance = actionAlliance;
  static const Color logVote = victorianGold;
  static const Color logCard = actionQuery;
  static const Color logEconomy = actionDraw;
  static const Color logSystem = rarityN;

  // ═══════════════════════════════════════════
  // 漸層預設
  // ═══════════════════════════════════════════
  /// 主背景漸層（深紫到更深紫）
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgPrimary, Color(0xFF120A22)],
  );

  /// 金色按鈕漸層
  static const LinearGradient goldButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, victorianGold, goldDim],
  );

  /// 羊皮紙紋理疊層（低透明度米色漸層模擬）
  static LinearGradient get parchmentOverlay => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          textPrimary.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      );

  // ═══════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════

  /// 根據稀有度取得對應顏色
  static Color getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'N':
      case 'NORMAL':
      case 'COMMON':
        return rarityN;
      case 'R':
      case 'RARE':
        return rarityR;
      case 'SR':
      case 'EPIC':
        return raritySR;
      case 'SSR':
      case 'LEGENDARY':
        return raritySSR;
      default:
        return rarityN;
    }
  }

  /// 稀有度光暈半徑
  static double getRarityGlowRadius(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'N':
        return 0;
      case 'R':
        return 4;
      case 'SR':
        return 8;
      case 'SSR':
        return 16;
      default:
        return 0;
    }
  }

  /// 稀有度邊框寬度
  static double getRarityBorderWidth(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'N':
        return 1.0;
      case 'R':
        return 1.5;
      case 'SR':
        return 2.0;
      case 'SSR':
        return 2.5;
      default:
        return 1.0;
    }
  }

  /// 根據段位 ELO 取得段位顏色
  static Color getRankColor(int elo) {
    if (elo >= 2000) return rankDiamond;
    if (elo >= 1800) return rankPlatinum;
    if (elo >= 1400) return rankGold;
    if (elo >= 1200) return rankSilver;
    return rankBronze;
  }

  /// 根據段位 ELO 取得段位光暈半徑
  static double getRankGlowRadius(int elo) {
    if (elo >= 2000) return 16;
    if (elo >= 1800) return 12;
    if (elo >= 1400) return 10;
    if (elo >= 1200) return 6;
    return 4;
  }

  /// 血條顏色（依血量漸變）
  static Color getHealthBarColor(double percentage) {
    if (percentage > 0.6) return actionAlliance;
    if (percentage > 0.3) return actionDraw;
    return roseRed;
  }

  /// 事件日誌重要度顏色
  static Color getEventColor(String importance) {
    switch (importance) {
      case 'normal':
        return textSecondary;
      case 'notable':
        return textPrimary;
      case 'critical':
        return roseLight;
      case 'reward':
        return victorianGold;
      default:
        return textSecondary;
    }
  }

  /// 選中角色強調背景色
  static const Color selectedCharacterBg = Color(0xFF3A2268);

  // ═══════════════════════════════════════════
  // 議會派系色系（Phase 2 — 多人制）
  // ═══════════════════════════════════════════
  /// 輝格黨：皇家藍
  static const Color whigBlue = Color(0xFF1A4A8C);

  /// 托利黨：深緋紅
  static const Color toryRed = Color(0xFF8C1A1A);

  /// 激進派：革命紫
  static const Color radicalPurple = Color(0xFF5A1A8C);

  /// 獨立議員：古銅金
  static const Color independentGold = Color(0xFF8C7A1A);

  /// 根據派系名稱取得對應顏色
  static Color getFactionColor(String faction) {
    switch (faction.toLowerCase()) {
      case 'whig':
      case 'labor':
        return whigBlue;
      case 'tory':
      case 'capital':
        return toryRed;
      case 'radical':
      case 'reform':
        return radicalPurple;
      case 'independent':
      case 'neutral':
      case 'crown':
        return independentGold;
      default:
        return independentGold;
    }
  }

  /// 根據派系取得派系標籤文字
  static String getFactionLabel(String faction) {
    switch (faction.toLowerCase()) {
      case 'whig':
      case 'labor':
        return 'Whig';
      case 'tory':
      case 'capital':
        return 'Tory';
      case 'radical':
      case 'reform':
        return 'Radical';
      case 'independent':
      case 'neutral':
      case 'crown':
        return 'Indep.';
      default:
        return 'Indep.';
    }
  }

  // ═══════════════════════════════════════════
  // 議案投票色
  // ═══════════════════════════════════════════
  /// FOR（贊成）：深綠
  static const Color voteFor = Color(0xFF1A5C2E);

  /// AGAINST（反對）：深紅
  static const Color voteAgainst = Color(0xFF5C1A1A);

  /// 辯論日誌卡牌名色
  static const Color logCardName = Color(0xFF9B72CF);
}
