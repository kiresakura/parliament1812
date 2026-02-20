import 'package:flutter/material.dart';

import '../../ui/theme/game_colors.dart';
import '../../ui/theme/game_animations.dart';

/// 行動順序條
///
/// 高度 ~40pt，水平置中排列圓點
/// 當前行動者圓點放大 + 金色高亮 + spring 彈跳
/// 自己的位置顯示 "YOU" 標籤
class TurnOrderView extends StatelessWidget {
  /// 玩家 ID 列表（按行動順序排列）
  final List<String> playerIds;

  /// 玩家名稱 map（id → name 首字）
  final Map<String, String> playerInitials;

  /// 當前行動者索引
  final int currentIndex;

  /// 玩家自己的索引
  final int myIndex;

  /// 各玩家的派系色（id → color）
  final Map<String, Color> playerFactionColors;

  const TurnOrderView({
    super.key,
    required this.playerIds,
    required this.playerInitials,
    required this.currentIndex,
    required this.myIndex,
    this.playerFactionColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(playerIds.length, (i) {
          final isCurrent = i == currentIndex;
          final isMe = i == myIndex;
          final playerId = playerIds[i];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 順序圓點
                AnimatedContainer(
                  duration: GameAnimation.turnOrderSwitchDuration,
                  curve: GameAnimation.turnOrderSwitchCurve,
                  width: isCurrent ? 18 : 12,
                  height: isCurrent ? 18 : 12,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? GameColors.victorianGold
                        : GameColors.bgSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GameColors.victorianGold.withValues(
                        alpha: isCurrent ? 1.0 : 0.4,
                      ),
                      width: 1,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: GameColors.victorianGold.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: isCurrent
                      ? Center(
                          child: Text(
                            playerInitials[playerId] ?? '',
                            style: const TextStyle(
                              color: GameColors.bgPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 2),
                // "YOU" 標籤
                if (isMe)
                  const Text(
                    'YOU',
                    style: TextStyle(
                      color: GameColors.victorianGold,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  const SizedBox(height: 7), // 佔位對齊
              ],
            ),
          );
        }),
      ),
    );
  }
}
