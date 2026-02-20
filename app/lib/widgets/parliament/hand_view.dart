import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card.dart';
import '../../services/haptic_service.dart';
import '../../ui/theme/game_colors.dart';
import '../../ui/theme/game_animations.dart';
import '../game_card_widget.dart';

/// 手牌區 — 弧形底部排列
///
/// 高度 ~180pt，卡牌呈扇形分佈
/// 選中卡牌上升 + 放大 + 金色光暈
/// 點擊選中，二次點擊出牌
class HandView extends ConsumerStatefulWidget {
  final List<GameCard> cards;
  final List<GameCard> playableCards;
  final ValueChanged<GameCard>? onCardPlayed;
  final ValueChanged<GameCard>? onCardTapped;

  const HandView({
    super.key,
    required this.cards,
    this.playableCards = const [],
    this.onCardPlayed,
    this.onCardTapped,
  });

  @override
  ConsumerState<HandView> createState() => _HandViewState();
}

class _HandViewState extends ConsumerState<HandView> {
  int? _selectedIndex;

  /// 弧形佈局角度計算
  List<double> _getArcAngles(int count) {
    if (count <= 1) return [0];
    if (count == 2) return [-5, 5];
    if (count == 3) return [-8, 0, 8];
    if (count == 4) return [-10, -4, 4, 10];
    if (count == 5) return [-10, -5, 0, 5, 10];
    // 超過 5 張：均勻分配 -12 ~ 12
    return List.generate(count, (i) {
      return -12.0 + (24.0 / (count - 1)) * i;
    });
  }

  /// Y 偏移（弧形：兩邊低，中間高）
  List<double> _getArcOffsets(int count) {
    if (count <= 1) return [0];
    return List.generate(count, (i) {
      final center = (count - 1) / 2.0;
      final distance = (i - center).abs() / center;
      return -8.0 * (1.0 - distance * distance); // 拋物線
    });
  }

  void _handleCardTap(int index) {
    final card = widget.cards[index];
    final isPlayable = widget.playableCards.contains(card);

    if (!isPlayable) return;

    if (_selectedIndex == index) {
      // 二次點擊：出牌
      HapticService.cardPlayed();
      widget.onCardPlayed?.call(card);
      setState(() => _selectedIndex = null);
    } else {
      // 首次點擊：選中
      HapticService.dragStart();
      widget.onCardTapped?.call(card);
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.cards.length;
    if (count == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            '暫無手牌',
            style: TextStyle(
              color: GameColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final angles = _getArcAngles(count);
    final offsets = _getArcOffsets(count);
    final cardWidth = count > 5 ? 70.0 : 85.0;
    final cardHeight = count > 5 ? 105.0 : 125.0;
    final spacing = count > 5 ? 46.0 : 56.0;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(count, (i) {
          final isSelected = _selectedIndex == i;
          final card = widget.cards[i];
          final isPlayable = widget.playableCards.contains(card);
          final xOffset = (i - (count - 1) / 2.0) * spacing;
          final yOffset = isSelected
              ? offsets[i] - 16 // 選中向上彈起
              : offsets[i];

          return AnimatedPositioned(
            duration: GameAnimation.cardSelectDuration,
            curve: GameAnimation.cardSelectCurve,
            left: MediaQuery.of(context).size.width / 2 + xOffset - cardWidth / 2,
            bottom: 10 - yOffset,
            child: GestureDetector(
              onTap: () => _handleCardTap(i),
              child: AnimatedContainer(
                duration: GameAnimation.cardSelectDuration,
                curve: GameAnimation.cardSelectCurve,
                transform: Matrix4.identity()
                  ..rotateZ(angles[i] * math.pi / 180)
                  // ignore: deprecated_member_use
                  ..scale(isSelected ? 1.05 : 1.0),
                transformAlignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: GameAnimation.cardSelectDuration,
                  decoration: BoxDecoration(
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: GameColors.victorianGold.withValues(alpha: 0.8),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                  child: GameCardWidget(
                    card: card,
                    isPlayable: isPlayable,
                    width: cardWidth,
                    height: cardHeight,
                    onTap: () => _handleCardTap(i),
                    onDragCompleted: isPlayable
                        ? (c) {
                            widget.onCardPlayed?.call(c);
                            setState(() => _selectedIndex = null);
                          }
                        : null,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
