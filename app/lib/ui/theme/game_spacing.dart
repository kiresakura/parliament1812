import 'package:flutter/material.dart';

/// 羅塞蒂間距 & 圓角 & 陰影系統 v2.0
class GameSpacing {
  GameSpacing._();

  // 間距（8px 基準）
  static const double screenPadding = 16.0;
  static const double cardPadding = 12.0;
  static const double cardGap = 8.0;
  static const double sectionGap = 16.0;

  // 圓角
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double badgeRadius = 4.0;
  static const double pillRadius = 20.0;

  // BorderRadius 便利
  static final BorderRadius cardBorderRadius =
      BorderRadius.circular(cardRadius);
  static final BorderRadius buttonBorderRadius =
      BorderRadius.circular(buttonRadius);
  static final BorderRadius badgeBorderRadius =
      BorderRadius.circular(badgeRadius);
  static final BorderRadius pillBorderRadius =
      BorderRadius.circular(pillRadius);
}

/// 羅塞蒂陰影系統 v2.0
class GameShadows {
  GameShadows._();

  /// 一般卡片陰影
  static const BoxShadow card = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    color: Color(0x80000000), // rgba(0,0,0,0.5)
  );

  /// 選中卡片金光
  static final BoxShadow selected = BoxShadow(
    offset: Offset.zero,
    blurRadius: 16,
    color: Color(0x99C9A84C), // rgba(201,168,76,0.6)
  );

  /// 按鈕陰影
  static const BoxShadow button = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 8,
    color: Color(0x66000000), // rgba(0,0,0,0.4)
  );
}
