import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../ui/theme/game_colors.dart';
import '../../ui/theme/game_fonts.dart';
import '../../ui/theme/game_animations.dart';

/// 對手資訊（從 Player 模型轉換）
class OpponentInfo {
  final String id;
  final String name;
  final String faction;
  final int handCount;
  final double influenceRatio; // 0.0 ~ 1.0
  final bool isActive;

  const OpponentInfo({
    required this.id,
    required this.name,
    required this.faction,
    required this.handCount,
    required this.influenceRatio,
    this.isActive = false,
  });

  Color get factionColor => GameColors.getFactionColor(faction);
  String get factionLabel => GameColors.getFactionLabel(faction);

  /// 從 Player 模型建立
  factory OpponentInfo.fromPlayer(
    Player player, {
    bool isActive = false,
    int maxReputation = 100,
  }) {
    return OpponentInfo(
      id: player.id,
      name: player.name,
      faction: player.character?.faction ?? 'neutral',
      handCount: player.handCards.length,
      influenceRatio: (player.reputation / maxReputation).clamp(0.0, 1.0),
      isActive: isActive,
    );
  }
}

/// 頂部對手縮略列
///
/// 4人模式：橫排 3 個對手卡片，HStack 置中
/// 8人模式：2行各 3-4 個，卡片縮小
class OpponentRailView extends StatelessWidget {
  final List<OpponentInfo> opponents;
  final bool isCompact; // 8人模式壓縮

  const OpponentRailView({
    super.key,
    required this.opponents,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact && opponents.length > 4) {
      return _buildCompactGrid();
    }
    return _buildStandardRow();
  }

  Widget _buildStandardRow() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: opponents.map((opp) {
          return Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OpponentCardView(opponent: opp),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactGrid() {
    // Split into 2 rows
    final mid = (opponents.length / 2).ceil();
    final row1 = opponents.sublist(0, mid);
    final row2 = opponents.sublist(mid);

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row1.map((opp) {
                return Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OpponentCardView(
                      opponent: opp,
                      compact: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row2.map((opp) {
                return Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OpponentCardView(
                      opponent: opp,
                      compact: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 單個對手卡片
class OpponentCardView extends StatelessWidget {
  final OpponentInfo opponent;
  final bool compact;

  const OpponentCardView({
    super.key,
    required this.opponent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 24.0 : 32.0;
    final factionColor = opponent.factionColor;

    return AnimatedContainer(
      duration: GameAnimation.cardSelectDuration,
      curve: GameAnimation.cardSelectCurve,
      padding: EdgeInsets.all(compact ? 4 : 6),
      decoration: BoxDecoration(
        color: GameColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: opponent.isActive
              ? GameColors.victorianGold
              : GameColors.victorianGold.withValues(alpha: 0.2),
          width: opponent.isActive ? 1.5 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 頭像 + 手牌數
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // 圓形頭像
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: GameColors.bgSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: factionColor, width: 2),
                      boxShadow: opponent.isActive
                          ? [
                              BoxShadow(
                                color: GameColors.victorianGold.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        opponent.name.isNotEmpty
                            ? opponent.name.substring(0, 1)
                            : '?',
                        style: TextStyle(
                          color: factionColor,
                          fontSize: compact ? 10 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // 手牌數徽章
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${opponent.handCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 2 : 4),
              // 玩家名
              if (!compact)
                Text(
                  opponent.name,
                  style: GameFont.uiLabel.copyWith(
                    color: GameColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: compact ? 1 : 2),
              // 派系標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: factionColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  opponent.factionLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 7 : 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              // 影響力條
              SizedBox(
                height: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: GameColors.bgSecondary,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: opponent.influenceRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GameColors.victorianGold,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          // 「行動中」標籤
          if (opponent.isActive)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(child: _ActiveBadge()),
            ),
        ],
      ),
    );
  }
}

/// 「行動中」金色膠囊標籤（呼吸脈衝）
class _ActiveBadge extends StatefulWidget {
  @override
  State<_ActiveBadge> createState() => _ActiveBadgeState();
}

class _ActiveBadgeState extends State<_ActiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GameAnimation.breathePulseDuration,
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: GameColors.victorianGold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '行動中',
              style: TextStyle(
                color: GameColors.bgPrimary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
