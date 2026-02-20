import 'package:flutter/material.dart';

import '../../ui/theme/game_colors.dart';
import '../../ui/theme/game_fonts.dart';
import '../../ui/theme/game_animations.dart';

/// 玩家 HUD 所需的資訊
class MyPlayerInfo {
  final String name;
  final String faction;
  final double influenceRatio; // 0.0 ~ 1.0
  final int ap; // 行動點數 0~4
  final int currentRound;
  final int totalRounds;
  final int handCount;

  const MyPlayerInfo({
    required this.name,
    required this.faction,
    required this.influenceRatio,
    this.ap = 3,
    this.currentRound = 1,
    this.totalRounds = 6,
    this.handCount = 0,
  });

  Color get factionColor => GameColors.getFactionColor(faction);
  String get factionLabel => GameColors.getFactionLabel(faction);
}

/// 玩家 HUD — 底部固定
///
/// 包含：頭像+派系、AP 圓點、回合數、影響力條、行動按鈕列
class PlayerHUDView extends StatelessWidget {
  final MyPlayerInfo player;
  final VoidCallback? onQuery;
  final VoidCallback? onSpeech;
  final VoidCallback? onAlliance;
  final VoidCallback? onEndSpeech;
  final bool isMyTurn;

  const PlayerHUDView({
    super.key,
    required this.player,
    this.onQuery,
    this.onSpeech,
    this.onAlliance,
    this.onEndSpeech,
    this.isMyTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameColors.bgSecondary.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: GameColors.victorianGold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上半：頭像資訊 + AP + 回合數
            Row(
              children: [
                // 左側：頭像 + 名字 + 派系
                _buildPlayerIdentity(),
                const Spacer(),
                // 右側：AP + 回合數
                _buildAPAndRound(),
              ],
            ),
            const SizedBox(height: 6),

            // 影響力條
            _InfluenceBar(ratio: player.influenceRatio),
            const SizedBox(height: 8),

            // 行動按鈕列
            Row(
              children: [
                // 質詢
                Expanded(
                  child: _ParliamentActionButton(
                    label: '質詢',
                    icon: Icons.chat_bubble,
                    color: const Color(0xFF1A3A5C),
                    onTap: isMyTurn ? onQuery : null,
                  ),
                ),
                const SizedBox(width: 8),
                // 演講
                Expanded(
                  child: _ParliamentActionButton(
                    label: '演講',
                    icon: Icons.mic,
                    color: const Color(0xFF4A1A6B),
                    onTap: isMyTurn ? onSpeech : null,
                  ),
                ),
                const SizedBox(width: 8),
                // 結盟
                Expanded(
                  child: _ParliamentActionButton(
                    label: '結盟',
                    icon: Icons.people,
                    color: const Color(0xFF1A4A2A),
                    onTap: isMyTurn ? onAlliance : null,
                  ),
                ),
                const SizedBox(width: 8),
                // 結束發言（40% 寬）
                Expanded(
                  flex: 2,
                  child: _EndSpeechButton(
                    onTap: isMyTurn ? onEndSpeech : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerIdentity() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 頭像
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GameColors.bgSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: player.factionColor, width: 2),
          ),
          child: Center(
            child: Text(
              player.name.isNotEmpty ? player.name.substring(0, 1) : '?',
              style: TextStyle(
                color: player.factionColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名字
            Text(
              player.name,
              style: GameFont.uiLabel.copyWith(
                color: GameColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // 派系標籤
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: player.factionColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                player.factionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAPAndRound() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AP 圓點
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: i < player.ap
                      ? GameColors.victorianGold
                      : GameColors.bgSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GameColors.victorianGold.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // 回合數
        Text(
          'ROUND ${player.currentRound}/${player.totalRounds}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: GameColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 影響力條（shimmer 光澤效果）
class _InfluenceBar extends StatefulWidget {
  final double ratio;

  const _InfluenceBar({required this.ratio});

  @override
  State<_InfluenceBar> createState() => _InfluenceBarState();
}

class _InfluenceBarState extends State<_InfluenceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: GameAnimation.shimmerSlideDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * widget.ratio;

          return Stack(
            children: [
              // 底層
              Container(
                decoration: BoxDecoration(
                  color: GameColors.bgCard,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // 填充
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: fillWidth,
                decoration: BoxDecoration(
                  color: GameColors.victorianGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            transform: _SlidingGradientTransform(
                              slidePercent: _shimmerController.value,
                            ),
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: GameColors.victorianGold),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gradient transform for shimmer
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 0.5),
      0,
      0,
    );
  }
}

/// 議會行動按鈕（質詢／演講／結盟）
class _ParliamentActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ParliamentActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_ParliamentActionButton> createState() =>
      _ParliamentActionButtonState();
}

class _ParliamentActionButtonState extends State<_ParliamentActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: GameAnimation.buttonPressDuration,
        curve: GameAnimation.buttonPressCurve,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon,
                    size: 14, color: GameColors.textPrimary),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: GameColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 結束發言按鈕（玫瑰紅，持續光暈）
class _EndSpeechButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _EndSpeechButton({this.onTap});

  @override
  State<_EndSpeechButton> createState() => _EndSpeechButtonState();
}

class _EndSpeechButtonState extends State<_EndSpeechButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: GameAnimation.buttonPulseDuration,
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseValue = _pulseAnimation.value;
          final borderOpacity = enabled ? 0.3 + pulseValue * 0.6 : 0.2;
          final shadowRadius = enabled ? 4.0 + pulseValue * 8.0 : 2.0;
          final scale = _isPressed ? 0.95 : (enabled ? 1.0 + pulseValue * 0.04 : 1.0);

          return AnimatedScale(
            scale: scale,
            duration: GameAnimation.buttonPressDuration,
            curve: GameAnimation.buttonPressCurve,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: GameColors.roseRed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GameColors.roseLight.withValues(alpha: borderOpacity),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.roseRed.withValues(
                        alpha: enabled ? 0.2 + pulseValue * 0.4 : 0.1,
                      ),
                      blurRadius: shadowRadius,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pan_tool, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '結束發言',
                      style: GameFont.uiLabel.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
