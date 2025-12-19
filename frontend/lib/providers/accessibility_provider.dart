import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

/// 無障礙設定提供者
/// 與 AccessibilitySettings (theme.dart) 同步
class AccessibilityProvider extends ChangeNotifier {
  // ==================== 字體大小設定 ====================
  static const double minFontScale = 0.8;
  static const double maxFontScale = 1.5;
  static const double defaultFontScale = 1.0;

  double _fontScale = defaultFontScale;
  double get fontScale => _fontScale;

  // ==================== 高對比模式 ====================
  bool _highContrast = false;
  bool get highContrast => _highContrast;

  // ==================== 減少動畫 ====================
  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;

  // ==================== 大字體模式 ====================
  bool _largeText = false;
  bool get largeText => _largeText;

  // ==================== 粗體文字 ====================
  bool _boldText = false;
  bool get boldText => _boldText;

  // ==================== 初始化 ====================
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = prefs.getDouble('fontScale') ?? defaultFontScale;
    _highContrast = prefs.getBool('highContrast') ?? false;
    _reduceMotion = prefs.getBool('reduceMotion') ?? false;
    _largeText = prefs.getBool('largeText') ?? false;
    _boldText = prefs.getBool('boldText') ?? false;

    // 同步到靜態 AccessibilitySettings
    _syncToTheme();
    notifyListeners();
  }

  /// 同步設定到 theme.dart 的 AccessibilitySettings
  void _syncToTheme() {
    AccessibilitySettings.fontScale = _fontScale;
    AccessibilitySettings.highContrast = _highContrast;
    AccessibilitySettings.reduceMotion = _reduceMotion;
    AccessibilitySettings.largeText = _largeText;
  }

  // ==================== 設定字體大小 ====================
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(minFontScale, maxFontScale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', _fontScale);
    _syncToTheme();
    notifyListeners();
  }

  // 增加字體大小
  Future<void> increaseFontSize() async {
    await setFontScale(_fontScale + 0.1);
  }

  // 減少字體大小
  Future<void> decreaseFontSize() async {
    await setFontScale(_fontScale - 0.1);
  }

  // 重設字體大小
  Future<void> resetFontSize() async {
    await setFontScale(defaultFontScale);
  }

  // ==================== 設定高對比模式 ====================
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', value);
    _syncToTheme();
    notifyListeners();
  }

  Future<void> toggleHighContrast() async {
    await setHighContrast(!_highContrast);
  }

  // ==================== 設定減少動畫 ====================
  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduceMotion', value);
    _syncToTheme();
    notifyListeners();
  }

  Future<void> toggleReduceMotion() async {
    await setReduceMotion(!_reduceMotion);
  }

  // ==================== 設定大字體模式 ====================
  Future<void> setLargeText(bool value) async {
    _largeText = value;
    if (value) {
      await setFontScale(1.3);
    } else {
      await setFontScale(defaultFontScale);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('largeText', value);
    _syncToTheme();
    notifyListeners();
  }

  Future<void> toggleLargeText() async {
    await setLargeText(!_largeText);
  }

  // ==================== 設定粗體文字 ====================
  Future<void> setBoldText(bool value) async {
    _boldText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('boldText', value);
    notifyListeners();
  }

  Future<void> toggleBoldText() async {
    await setBoldText(!_boldText);
  }

  // ==================== 重設所有設定 ====================
  Future<void> resetAll() async {
    await setFontScale(defaultFontScale);
    await setHighContrast(false);
    await setReduceMotion(false);
    await setLargeText(false);
    await setBoldText(false);
  }

  // ==================== 工具方法 ====================
  // 獲取字體大小標籤
  String get fontSizeLabel {
    if (_fontScale <= 0.85) return '小';
    if (_fontScale <= 1.05) return '標準';
    if (_fontScale <= 1.25) return '大';
    return '超大';
  }

  // 獲取縮放後的文字樣式
  TextStyle scaleTextStyle(TextStyle style) {
    double fontSize = (style.fontSize ?? 16) * _fontScale;
    FontWeight? fontWeight = style.fontWeight;

    if (_boldText && (fontWeight == null || fontWeight.index < FontWeight.w600.index)) {
      fontWeight = FontWeight.w600;
    }

    return style.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  // 獲取動畫時長（減少動畫模式下返回0）
  Duration getAnimationDuration(Duration normalDuration) {
    if (_reduceMotion) {
      return Duration.zero;
    }
    return normalDuration;
  }

  // 獲取動畫曲線（減少動畫模式下返回線性）
  Curve getAnimationCurve(Curve normalCurve) {
    if (_reduceMotion) {
      return Curves.linear;
    }
    return normalCurve;
  }

  // ==================== 適應性顏色取得器 ====================
  /// 根據高對比模式取得適應性顏色
  Color adaptiveColor(Color normalColor, Color highContrastColor) {
    return _highContrast ? highContrastColor : normalColor;
  }

  /// 取得背景色
  Color get backgroundColor => adaptiveColor(
    AppTheme.primaryBackground,
    HighContrastColors.primaryBackground,
  );

  /// 取得卡片背景色
  Color get cardBackgroundColor => adaptiveColor(
    AppTheme.cardBackground,
    HighContrastColors.cardBackground,
  );

  /// 取得強調色
  Color get accentColor => adaptiveColor(
    AppTheme.accentGold,
    HighContrastColors.accentGold,
  );

  /// 取得主要文字色
  Color get textPrimaryColor => adaptiveColor(
    AppTheme.textPrimary,
    HighContrastColors.textPrimary,
  );

  /// 取得次要文字色
  Color get textSecondaryColor => adaptiveColor(
    AppTheme.textSecondary,
    HighContrastColors.textSecondary,
  );

  /// 取得成功色
  Color get successColor => adaptiveColor(
    AppTheme.successColor,
    HighContrastColors.successColor,
  );

  /// 取得錯誤色
  Color get errorColor => adaptiveColor(
    AppTheme.errorColor,
    HighContrastColors.errorColor,
  );

  /// 取得警告色
  Color get warningColor => adaptiveColor(
    AppTheme.warningColor,
    HighContrastColors.warningColor,
  );

  /// 取得投票贊成色
  Color get voteAyeColor => adaptiveColor(
    AppTheme.voteAye,
    HighContrastColors.voteAye,
  );

  /// 取得投票反對色
  Color get voteNayColor => adaptiveColor(
    AppTheme.voteNay,
    HighContrastColors.voteNay,
  );

  /// 根據角色類型取得適應性顏色
  Color getRoleColor(String roleType) {
    if (!_highContrast) {
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

  /// 根據政黨取得適應性顏色
  Color getPartyColor(String party) {
    if (!_highContrast) {
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

  /// 取得適應性邊框色
  Color get borderColor => adaptiveColor(
    AppTheme.accentGold.withValues(alpha: 0.3),
    HighContrastColors.textPrimary.withValues(alpha: 0.5),
  );

  /// 取得適應性陰影
  List<BoxShadow> get adaptiveShadow => _highContrast
      ? [] // 高對比模式下不使用陰影，改用清晰邊框
      : AppTheme.cardShadow;
}

// 注意：HighContrastColors 已移至 theme.dart，避免重複定義
// 請使用 import '../config/theme.dart' 來存取 HighContrastColors
